class AppLink < ActiveRecord::Base
  attr_accessible :slug, :downloads_count, :max_downloads, :expires_at, :segment

  belongs_to :sharer, class_name: "User"

  validates :slug, presence: true

  def usable?
    downloads_left? and !expired?
  end

  def expired?
    expires_at.present? and Time.now > expires_at
  end

  def downloads_left?
    max_downloads.blank? or max_downloads >= downloads_count
  end
end
