class Invite < ActiveRecord::Base
  attr_accessible :phone, :inviter, :conversation, :accepted, :tracked, :cohort

  belongs_to :inviter, class_name: "User"
  belongs_to :conversation

  scope :pending, where(accepted: false)
  scope :waitlisted, where(waitlisted: true)
  scope :not_waitlisted, where("waitlisted is not true")
  scope :pending_for_user, lambda { |user| pending.where(phone: user.phone_normalized) }
  default_scope not_waitlisted

  validates :phone, presence: true

  def self.find_all_by_phone(phone)
    phone = Phoner::Phone.parse(phone).to_s
    self.where(:phone => phone)
  end

  def waitlisted!
    self.waitlisted = true
    save!
  end

  def accepted?
    accepted
  end

  def accept!(user)

    self.transaction do

      invite_type = "explicit"
      if (conversation)
        conversation.members << user
        invite_type = "implicit"
      end

      if(tracked == false)   #track it, then mark it as tracked
        tracked = true
        data = {
            invites: [] << phone,
            already_invited: []
        }
        MetricsPublisher.publish(user, "users:invite:#{invite_type}", data)
      end

      self.accepted = true
      save!
    end

    MetricsPublisher.publish(user, "invite:accept", {invite_id: self.id, invite_type: 'phone'})
  end

  def also_known_as(obj={})
    user = obj[:for]
    contact = user.contacts.where(phone_hashed: phone_hashed).first
    contact.present? ? contact.name : phone
  end

  def phone_hashed
    Digest::MD5.hexdigest(phone)
  end

  def self.accept_all!(user)
    invites = Invite.where(phone: user.phone_normalized)

    for invite in invites
      unless invite.conversation.nil?
        next if invite.conversation.members.exists?(user)
      end
      invite.accept! user
    end
  end
end
