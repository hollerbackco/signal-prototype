class Conversation < ActiveRecord::Base
  attr_accessible :creator, :name

  has_many :videos, order: "videos.created_at DESC", :dependent => :destroy
  has_many :memberships, :dependent => :destroy
  has_many :members, through: :memberships, source: :user, class_name: "User"
  has_many :invites, conditions: {accepted: false}
  has_many :texts, order: "texts.created_at DESC", :dependent => :destroy

  belongs_to :creator, class_name: "User"

  default_scope order("updated_at DESC")

  def self.find_by_members(users)
    raise if users.blank?
    user_ids = users.map(&:id).join(",")

    ids = Membership.unscoped.joins(:user)
      .group("memberships.conversation_id")
      .having("array_agg(memberships.user_id) <@ ARRAY[#{user_ids}] and array_agg(memberships.user_id) @> ARRAY[#{user_ids}]")
      .select("memberships.conversation_id")
      .map(&:id)

    self.find_by_id(ids)
  end

  def self.find_by_phones(phones)
    raise if phones.blank?
    raise if !phones.is_a? Array
    phones = phones.uniq.sort

    # fix this. this is ridiculously slow
    includes(:members, :invites).all.select do |c|
      same = (phones == c.involved_phones.uniq.flatten.sort)
    end
  end

  # all conversations with a name that is set.
  def group?
    members.count > 2 or self[:name].present?
  end
  alias_method :is_group, :group?

  def member_names(discluded_user=nil)
    names = members.map {|user| user.username }.join(",")
    members.any? ? names : nil
  end

  def involved_phones
    members.map(&:phone_normalized) + invites.map(&:phone)
  end

  def self.find_by_phone_numbers(user, invites)
    #todo do this with sql
    parsed_numbers = Signal::ConversationInviter.parse(user,invites)
    parsed_numbers = parsed_numbers + [user.phone_normalized]

    user.member_of.keep_if do |conversation|
      numbers = conversation.involved_phones
      parsed_numbers.count == numbers.count && (parsed_numbers - conversation.involved_phones).empty?
    end.first
  end
end
