class Message < ActiveRecord::Base

  class Type
    VIDEO = "video"
    TEXT = "text"
    IMAGE = "image"

    QUALIFIED_TYPE_REGEX = '(video\Z|text\Z|image\Z)'
  end

  belongs_to :membership

  serialize :content, ActiveRecord::Coders::Hstore

  attr_accessor :display

  scope :seen, where("seen_at is not null")
  scope :unseen, where(:seen_at => nil)
  scope :unseen_within_memberships, lambda { |ids| where("messages.seen_at is null AND messages.membership_id IN (?)", ids) }
  scope :received, where("is_sender IS NOT TRUE")
  scope :sent, where("is_sender IS TRUE")
  scope :updated_since, lambda { |updated_at| where("messages.updated_at > ? ", updated_at) }
  scope :updated_since_within_memberships, lambda { |updated_at, ids| where("messages.updated_at > ? AND messages.membership_id IN (?)", updated_at, ids) }
  scope :before_last_message_at, lambda { |before_message_time, ids| where("messages.seen_at is null AND messages.updated_at < ? AND messages.membership_id IN (?)", before_message_time, ids) }
  scope :before, lambda { |time| where("messages.sent_at < ?", time) }
  scope :watchable, where("CAST(content->'guid' as text) is not null")

  after_create do |record|
    m = record.membership
    m.deleted_at = nil
    m.last_message_at = record.sent_at || record.created_at
    if (!record.sender? or m.most_recent_thumb_url.blank?) && (record.message_type != Type::TEXT)
      if !record.ttyl?
        m.most_recent_thumb_url = record.thumb_url
      end
    end
    m.most_recent_subtitle = record.subtitle
    m.save
  end

  def sender?
    is_sender
  end

  def self.find_by_guid(str)
    self.all_by_guid(str).first
  end

  def self.all_by_guid(str)
    where("content -> 'guid'='#{str}'")
  end

  def self.sync_objects(opts={})
    raise ArgumentError if opts[:user].blank?
    options = {
        :since => nil,
        :before => nil,
        :membership_ids => []
    }.merge(opts)

    api_version = opts[:api_version]

    collection = []

    collection = options[:user].messages.watchable

    collection = if options[:since]
                   collection.updated_since_within_memberships(options[:since], options[:membership_ids])
                 elsif options[:before]
                   collection.before_last_message_at(options[:before], options[:membership_ids])
                 else #how much of an improvement will one query be? Quite a bit!
                   collection.unseen_within_memberships(options[:membership_ids])
                 end
    begin
      Message.set_message_display_info(collection, api_version)
    rescue Exception => e
      logger.error e
    end
    collection.map(&:to_sync_v1)
  end

  #Deprecated
  def to_sync(opts={})
    {#TODO: deprecate this clause and delete once we get all clients
     type: "message",
     sync: as_json()
    }
  end

  def as_json(opts={})
    options = {}
    if (message_type == Type::TEXT)
      payload = :text
    else
      payload = :video
    end
    options = options.merge({:methods => [:type, :conversation_id, :sender_id, :user, :is_deleted, payload]})
    #options = options.merge(:methods => [:guid, :url, :thumb_url, :gif_url, :conversation_id, :user, :is_deleted, :subtitle, :display])
    options = options.merge(opts)
    options = options.merge(:only => [:created_at, :sender_name, :sent_at, :needs_reply])
    super(options).merge({is_read: !unseen?})
  end

  #after text support
  def to_sync_v1

    {
        type: "message",
        sync: as_json()
    }
  end

  def user
    {
        name: sender_name,
    }
  end

  def ttyl?
    !content.key? "guid"
  end

  def url
    content["url"]
  end

  def thumb_url
    content["thumb_url"]
  end

  def gif_url
    content["gif_url"]
  end

  def subtitle
    (content["subtitle"] || "").force_encoding("UTF-8")
  end

  def guid
    content["guid"]
  end

  def text_content
    content["text"]
  end

  def text
    {:guid => guid, :text => text_content}
  end

  def video
    {:guid => guid, :url => url, :thumb_url => thumb_url, :gif_url => gif_url, :subtitle => subtitle}
  end

  def video_guid=(str)
    content["guid"] = str
  end

  def filename
    Video.find_by_guid(content["guid"]).filename
  end

  def unseen?
    seen_at.blank?
  end

  def seen?
    seen_at.present?
  end

  def seen!
    self.class.transaction do
      membership.touch
      self.seen_at = Time.now
      self.save!
    end
  end

  def type
    message_type
  end

  def delete!
    self.class.transaction do
      self.deleted_at = Time.now
      self.save!
    end
  end

  def deleted?
    deleted_at.present?
  end

  alias_method :is_deleted, :deleted?

  def conversation_id
    membership_id
  end


  def self.set_message_display_info(messages, api_version)

    rules = {}
    if (api_version == SignalApp::ApiVersion::V1)
      return
      #rules = SignalApp::ClientDisplayManager.get_rules_by_name('content_cell_display_rules')
    else
      rules = SignalApp::ClientDisplayManager.get_rules_by_name('video_cell_display_rules')
    end

    #user display info
    user_display = rules['user']

    #other display info
    other_display = rules['others']

    #for each message add it's display info
    messages.each do |message|
      message.is_sender? ? message.display = user_display : message.display = other_display
    end

  end
end
