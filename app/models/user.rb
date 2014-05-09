require 'digest/md5'
class User < ActiveRecord::Base
  include Signal::SecurePassword

  # array of blocked users
  serialize :muted, Array

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(?:\.[a-z\d\-]+)*\.[a-z]+\z/i

  #has_secure_password
  attr_accessible :name, :email, :phone, :phone_hashed, :username,
    :password, :password_confirmation, :phone_normalized,
    :device_token, :last_app_version, :cohort

  has_many :devices, autosave: true, :dependent => :destroy
  has_many :memberships, :dependent => :destroy
  has_many :messages, through: :memberships, :dependent => :destroy
  has_many :videos
  has_many :texts
  has_many :invites,
    :foreign_key => :inviter_id,
    :class_name => "Invite"

  has_many :email_invites, :foreign_key => :inviter_id, :class_name => "EmailInvite"

  has_many :friendships
  has_many :friends, :through => :friendships
  has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
  has_many :inverse_friends, :through => :inverse_friendships, :source => :user

  has_many :conversations, through: :memberships
  has_many :contacts
  has_one  :reactivation, :dependent => :destroy

  before_create :set_last_active_at
  before_create :set_access_token
  before_create :set_verification_code
  before_validation :downcase_username
  before_validation :downcase_email

  validates :email,
    presence: true,
    uniqueness: true,
    format: { with: VALID_EMAIL_REGEX, :message => "must be valid"}
  validates :username,
      presence: true,
      uniqueness: true,
      format: { :with => /\A_?[a-z]_?(?:[a-z0-9]_?)*\z/i, :message => "must be letters, numbers and underscores" }
  validate :phone_must_be_valid

  scope :unverified, where(:verification_code => nil)

  def self.android
    User.where(:id => Device.android.pluck("distinct user_id"))
  end

  def unadded_friends
    inverse_friends - friends
  end

  #def friends
    #user_ids = Membership.where(:conversation_id => conversations).map(&:user_id).uniq
    #user_ids = user_ids - [self.id]
    #User.where(:id => user_ids)
  #end

  def set_last_active_at
    self.last_active_at = Time.now
  end

  def phone_must_be_valid
    if phone.blank?
      errors[:base] << "Phone number cannot be blank"
      return
    end
    if phone_normalized.blank?
      errors[:base] << "Invalid phone number"
      return
    end
    user = User.find_by_phone_normalized(phone_normalized)
    if user and self.id != user.id
      errors[:base] << "Phone number is taken"
      return
    end
  end

  def active?(since=nil)
    since = Time.now - 1.day if since.blank?
    messages.sent.where("sent_at > ?", since).any?
  end

  #Not Used
  def active_within_days?(days)
    Time.now - last_active_at
  end

  #def last_active_at
  #  message = messages
  #    .sent
  #    .reorder("sent_at DESC")
  #    .first
  #
  #  message.present? ? message.sent_at : Time.now
  #end

  def unseen_memberships_count
    messages.watchable.unseen.group_by(&:membership_id).length
  end

  def unseen_messages
    messages.watchable.unseen.received.reorder("messages.sent_at DESC")
  end

  def muted?(user)
    user = User.find(user) if user.is_a? Integer

    self[:muted].include? user.id
  end

  def mute!(user)
    user = User.find(user) if user.is_a? Integer
    return true if muted?(user)

    self[:muted] << user.id
    save!
  end

  def unmute!(user)
    user = User.find(user) if user.is_a? Integer
    return true if !muted?(user)

    self[:muted].delete(user.id)
    save!
  end

  def muted_users
    muted.map {|uid| User.find(uid) }
  end

  def memcache_key_touch
    SignalApp::BaseApp.settings.cache.set("user/#{id}/memcache-id", self.memcache_id + 1)
  end

  def memcache_id
    SignalApp::BaseApp.settings.cache.fetch("user/#{id}/memcache-id") do
      rand(10)
    end
  end

  def memcache_key
    "user/#{id}-#{memcache_id}"
  end

  def device_for(token, platform, platform_version=nil)
    if token.blank? and platform.blank?
      gen = devices.general.first
      return gen if gen.present?
    end
    devices.where({
      :platform => (platform || "ios"),
      :token => token,
      :platform_version => platform_version
    }).first_or_create
  end

  #todo get rid of this
  def access_token
    devices.general.any? ? devices.general.first.access_token : ""
  end

  def member_of
    Conversation.joins(:members).where("users.id" => [self])
  end

  def also_known_as(obj={})
    user = obj[:for]
    contact = user.contacts.where(phone_hashed: phone_hashed).first
    contact.present? ? contact.name : (name || username)
  end

  def self.authenticate(phone, code, password)
    user = User.find_by_phone_normalized(phone)
    if user  && user.try(:authenticate, password) and user.verify!(code)
      user
    else
      nil
    end
  end

  def self.authenticate_with_code(phone, code)
    user = User.find_by_phone_normalized(phone)
    if user && user.verify!(code)
      user
    else
      nil
    end
  end

  def self.authenticate_with_email(matcher, password)
    user = User.find_by_email(matcher)
    unless user
      user = User.find_by_username(matcher)
    end
    user.try(:authenticate, password)
  end

  def self.authenticate_with_access_token(access_token)
    if device = Device.find_by_access_token(access_token)
      device.user
    else
      nil
    end
  end

  def phone_hashed
    return self[:phone_hashed] if self[:phone_hashed].present?

    self.phone_hashed = Digest::MD5.hexdigest(phone_normalized)
    save && self.phone_hashed
  end

  def phone=(phone)
    self.phone_normalized = Phoner::Phone.parse(phone).to_s
    super
  end

  def phone_area_code
    phoner.present? ? phoner.area_code : "858"
  end

  def phone_country_code
    phoner.present? ? phoner.country_code : "1"
  end

  def verified?
    self.verification_code.blank?
  end
  alias_method :is_verified, :verified?

  def verify(code)
    self.verification_code == code
  end

  def reset_verification_code!
    set_verification_code
    save!
  end

  def verify!(code)
    if self.verification_code == code
      self.verification_code = nil
      save!
    elsif code == '00007' && ENV["RACK_ENV"] != "production" #mark this user as a tester
      self.verification_code = nil
      self.is_tester = true
      save!
    end
    verified?
  end

  def new?
    !self.verification_code.blank?
  end
  alias_method :is_new, :new?

  def has_sent?
    messages.sent.any?
  end

  def as_json(options={})
    #TODO: uncomment when we add this to the signup flow
    options = options.merge(:only => [:id, :phone, :phone_normalized, :username, :name, :created_at])
    options = options.merge(:methods => [:phone_hashed, :is_new, :is_verified])
    super(options)
  end

  def meta
    {
      id: id,
      name: username,
      username: username,
      phone: phone_normalized,
      videos_sent: videos.count,
      texts_sent: texts.count,
      cohort: cohort
    }
  end


  def device_names
    devices.map(&:description).compact.join(",")
  end

  def set_verification_code
    self.verification_code ||= SecureRandom.random_number(8999) + 1000
  end

  private

  def phoner
    @phoner ||= Phoner::Phone.parse(phone_normalized)
  end

  def set_access_token
    self.access_token = loop do
      access_token = ::Signal::Random.friendly_token(40)
      break access_token unless User.find_by_access_token(access_token)
    end
  end

  def downcase_username
    self.username = username.downcase
  end

  def downcase_email
    self.email = email.downcase
  end
end

# February 5, 2014 -- jeff was here
