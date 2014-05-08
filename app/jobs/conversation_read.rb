class ConversationRead
  include Sidekiq::Worker

  def perform(user_id)
    current_user = User.find(user_id)

    MetricsPublisher.publish(current_user, "conversations:list")
  end
end
