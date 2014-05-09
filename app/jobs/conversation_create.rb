class ConversationCreate
  include Sidekiq::Worker

  def perform(user_id, conversation_id, invites, actual_invites)
    user = User.find(user_id)
    conversation = Conversation.find(conversation_id)

    data = {
      :name => conversation.name,
      :total_invited_count => actual_invites.count,
      :already_invited_count => (invites - actual_invites).count,
      :already_users_count => conversation.members.count,
      :conversation_count => user.conversations.count
    }
    MetricsPublisher.publish(user, "conversations:create", data)

    #don't publish the metrics until it's been confirmed by the client
    publish_invited(user, invites, actual_invites)
  end

  private

  def publish_invited(user, invites, actual_invites)
    phones = actual_invites
    phones.each do |phone|
      data = {
        invited_phone: phone
      }
      MetricsPublisher.publish(user, "users:invite", data)
    end


    #data = {
    #    invites: actual_invites,
    #    already_invited: (invites - actual_invites)
    #}
    #MetricsPublisher.publish(user, "users:invite:implicit", data)
    #
    #p "publish metric: users:invite:implicit with data: #{data}"
    #
    #if actual_invites.any?
    #  Signal::BMO.say("#{user.username} invited #{actual_invites.count} people through a conversation")
    #end
  end
end
