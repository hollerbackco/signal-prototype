class EmailInvite < ActiveRecord::Base
  attr_accessible :cohort

  belongs_to :inviter, class_name: "User"

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(?:\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX}

  before_save {self.email = email.downcase}

  def accept!(user)
    self.accepted = true
    save

    #to prevent double counting in metrics and analysis, ensure that count_unique is done on user.id
    MetricsPublisher.publish(user, "invite:accept", {invite_type: 'email'})
  end

  def self.accept_all!(user)
    invites = EmailInvite.where(email: user.email)
    invites.each do |invite|
      invite.accept!(user)
    end
  end
end