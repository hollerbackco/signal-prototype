# a membership is a subscription to a conversation
# memberships is a subsciption to a topic
# memberships can also publish to that topic
class Membership < ActiveRecord::Base
  attr_accessible :following
  belongs_to :user
  belongs_to :conversation
  has_many :messages

  delegate :invites, to: :conversation

  default_scope { order("last_message_at DESC") }

  before_create { |record| record.last_message_at = Time.now }

  scope :updated_since, lambda { |updated_at| where("memberships.updated_at > ?", updated_at) }
  scope :updated_since_with_limit, lambda { |updated_at, count| where("memberships.updated_at > ?", updated_at).limit(count) }
  scope :before_last_message_at_with_limit, lambda { |before_message_at, count| where("memberships.updated_at < ?", before_message_at).limit(count) }
  scope :before_last_message_at, lambda { |before_message_at| where("memberships.updated_at < ?", before_message_at) }

  def self.sync_objects(opts={})
    raise ArgumentError if opts[:user].blank? and !opts[:user].is_a? User
    options = {
        :since => nil,
        :before => nil,
        :count => nil,
    }.merge(opts)

    api_version = opts[:api_version]

    collection = self.where(user_id: options[:user].id)

    if options[:since]
      if (options[:count])
        collection = collection.updated_since_with_limit(options[:since], options[:count])
      else
        collection = collection.updated_since(options[:since])
      end

    elsif options[:before]
      if (options[:count])
        collection = collection.before_last_message_at_with_limit(options[:before], options[:count])
      else
        collection = collection.before_last_message_at(options[:before])
      end
    else
      if (options[:count])
        collection = collection.where("memberships.deleted_at IS null").limit(options[:count])
      else
        collection = collection.where("memberships.deleted_at IS null") #limit the number we send if it's set
      end

    end

    join_clause = "LEFT OUTER JOIN messages ON memberships.id = messages.membership_id AND messages.seen_at is null AND CAST(messages.content->'guid' as text) is not null"

    collection = collection
    .joins(join_clause)
    .group("memberships.id")
    .select('memberships.*, count(messages) as unseen_count')

    return collection.map(&:to_sync), collection.map { |membership| membership.id }

  end

  #method not called because user can explicitly set the subtitle
  def seen_without_response
    message = messages.watchable.last
    subtitle = message.subtitle
    all_messages = Message.all_by_guid(message.guid)

    # subtract sender
    seen_count = all_messages.select { |m| m.seen? }.count - 1

    if seen_count > 1
      string = "seen by #{seen_count} people"
    else
      string = "seen by #{user.username}"
    end

    all_messages.each do |m|
      m.content["subtitle"] = string
      membership = m.membership
      membership.most_recent_subtitle = string
      m.save
      membership.save
    end
  end

  def ttyl
    message = messages.new
    #message.content["subtitle"] = "seen"
    message.is_sender = true
    message.sender_name = user.also_known_as(for: user)
    message.save

    recipient_memberships.each do |m|
      message = m.messages.new
      message.is_sender = false
      message.sender_name = user.also_known_as(for: m.user)
      #message.content["subtitle"] = "ttyl"
      message.save
    end
  end

  def recipient_memberships
    conversation.memberships - [self]
  end

  def others
    conversation.members - [user]
  end

  def members
    # others.map do |other|
    #   {
    #       id: other.id,
    #       name: other.also_known_as(for: user),
    #       username: other.username,
    #       is_blocked: user.muted?(other)
    #   }
    #end
    Membership.joins("inner join users on memberships.user_id = users.id").where(:conversation_id => conversation_id).select([:username, :user_id, :following]).map { |e| {:username => e.username,:user_id => e.user_id, :following => e.following, :name  => User.find(e.user_id).also_known_as(:for => user ) } }
  end

  def following?
    following
  end

  # todo: cache this
  def name
    update_conversation_name if self[:name].blank?
    self[:name]
  end

  def update_conversation_name
    self.name = auto_generated_name
    save!
  end

  def auto_generated_name
    return conversation.name if conversation.name.present?
    names = others.map { |other| other.also_known_as(:for => user) }
    names = names + conversation.invites.map do |invite|
      invite.also_known_as(:for => user)
    end
    name = names.join(", ").truncate(100).strip

    name.blank? ? "no one's here" : name
  end

  def videos
    # TODO cleanup and no longer have this in the json
    messages.limit(10)
  end

  def unseen?
    messages.watchable.unseen.present?
  end

  def archived?
    self.is_archived
  end

  def view_all(message_types)
    if (message_types == nil)
      messages.unseen.each { |m| m.seen! }
    else
      messages.unseen.where("message_type in (?)", message_types).each { |m| m.seen! }
    end
  end

  def group?
    conversation.group?
  end

  alias_method :is_group, :group?

  def unseen_count
    self["unseen_count"] || messages.watchable.received.unseen.count
  end

  alias_method :unread_count, :unseen_count

  def update_seen!
    touch
  end

  def is_deleted
    self.deleted_at.present?
  end

  def leave!
    self.class.transaction do
      self.deleted_at = Time.now
      save!
      self.messages.destroy_all
    end
  end

  def sender_name
    conversation.creator.also_known_as(:for => user)
  end

  def as_json(opts={})
    options = {}
    options = options.merge(methods: [:name, :unread_count, :is_deleted, :is_archived, :members, :sender_name])
    options = options.merge(except: [:updated_at, :conversation_id])
    options = options.merge(opts)
    obj = super(options)

    # TODO cleanup updated_at [hacky][ios]
    # override updated_at timestamp to allow for correct sorting on older versions of the ios app
    obj.merge({updated_at: last_message_at})
  end

  def to_sync
    {
        type: "conversation",
        sync: as_json
    }
  end
end
