class StreamJob < ActiveRecord::Base
  belongs_to :video

  def complete!
    video.streamname = "#{master_playlist}.m3u8"
    video.save!

    self.state = "complete"
    save!
  end
end
