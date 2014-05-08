class Video < ActiveRecord::Base
  if Sinatra::Base.production?
    BUCKET_NAME = "hb-media"
    CLOUDFRONT_URL = "http://d2qyqd6d7y0u0k.cloudfront.net"
  else
    BUCKET_NAME = "hb-media-dev"
    CLOUDFRONT_URL = "https://s3.amazonaws.com/hb-media-dev"
  end

  attr_accessible :filename, :user, :conversation,
    :in_progress, :subtitle, :guid, :stitch_request
  #acts_as_readable :on => :created_at

  serialize :stitch_request, ActiveRecord::Coders::Hstore

  belongs_to :user
  belongs_to :conversation
  #has_many :messages, :foreign_key => "content_guid", :dependent => :destroy

  default_scope order("created_at DESC")

  before_validation do |record|
    record.guid ||= SecureRandom.uuid
  end

  after_destroy do |record|
    Message.all_by_guid(record.guid.to_s).destroy_all
  end

  def self.random_label
    "#{SecureRandom.hex(1).upcase}/#{SecureRandom.uuid.upcase}"
  end

  # prepare the video
  def ready!
    self.in_progress = false
    save!
  end

  def recipients
    return [] if conversation.blank?
    conversation.members - [user]
  end

  def url
    return "" if filename.blank?
    #HollerbackApp::BaseApp.settings.cache.fetch("video-url-#{id}", 1.week) do
    #video_object.public_url
    [CLOUDFRONT_URL, video_object.key].join("/")
    #end
  end

  def thumb_url
    return "" if filename.blank?
    #return "" unless thumb_object.exists?

    #HollerbackApp::BaseApp.settings.cache.fetch("video-thumb-url-#{id}", 1.week) do
    [CLOUDFRONT_URL, thumb_object.key].join("/")
    #end
  end

  def gif_url
    return "" if filename.blank?

    [CLOUDFRONT_URL, gif_object.key].join("/")

  end

  def metadata
    video_object.metadata
  end

  def content_hash
    {
      guid: guid,
      url: url,
      thumb_url: thumb_url,
      subtitle: subtitle,
      gif_url: gif_url
    }
  end

  def self.video_urls
    bucket.objects.map {|o| o.url_for(:read)}
  end

  def as_json(options={})
    options = options.merge(:methods => [:url, :thumb_url])
    super(options)
  end

  def self.bucket_by_name(name)
    AWS::S3.new.buckets[name]
  end

  def self.bucket
    @bucket ||= AWS::S3.new.buckets[BUCKET_NAME]
  end

  def to_code
    (id + 999999999).to_s(24)
  end

  def self.find_by_code(code)
    code = code.to_i(24) - 999999999
    find(code)
  end

  private

  def video_object
    self.class.bucket.objects[filename]
  end

  def thumb_object
    thumb = filename.split(".").first << "-thumb.png"
    self.class.bucket.objects[thumb]
  end

  def gif_object
    gif = filename.split(".").first << ".gif"
    self.class.bucket.objects[gif]
  end
end
