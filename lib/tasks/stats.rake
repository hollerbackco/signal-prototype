namespace :stats do
  desc "puts stats"
  task :get => :uncache do
    ActiveRecord::Base.logger = nil
    puts "================================"
    puts "total users: #{stats.users_count}"
    puts "total conversations: #{stats.conversations_count}"
    puts "================================"
    puts "total sent: #{stats.videos_sent_count}"
    puts "total recieved: #{stats.videos_received_count}"
    puts "================================"
    puts "avg members per conversation: #{stats.members_in_conversations_avg}"
    puts "avg videos per conversation: #{stats.videos_in_conversations_avg}"
    puts "================================"
    puts "unread videos: #{stats.videos_unread_count}"
    puts "avg videos per conversation: #{stats.videos_in_conversations_avg}"
    puts "================================"
  end

  desc "cache values of the stats"
  task :cache => :uncache do
  end

  desc "uncache all"
  task :uncache do
    stats.uncache_all
  end

  desc "send videos to aws to compute"
  task :compute do
    Video.where("user_id is not null").find_in_batches(batch_size: 10) do |videos|
      messages = []
      videos.each do |video|
        messages << {
          message_body: {
            user_id: video.user_id,
            video_id: video.id,
            video_location: video.filename,
            video_url: video.url,
            created: video.created_at,
            recipient_count: video.recipients.count
          }.to_json
        }
      end
      stats.batch_enqueue messages
    end
  end

  def stats
    @stats ||= Hollerback::Statistics.new
  end
end
