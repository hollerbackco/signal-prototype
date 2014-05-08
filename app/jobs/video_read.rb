class VideoRead
  include Sidekiq::Worker

  def perform(message_ids, user_id, watched_at=nil)
    current_user = User.find(user_id)
    messages = Message.find(message_ids)

    notify_analytics(messages, current_user)
  end

  private

  def notify_analytics(messages, current_user)
    messages.each do |message|
      data = {
        message_id: message.id,
        content_guid: message.guid
      }
      MetricsPublisher.publish(current_user, "video:watch", data)
    end
  end
end
