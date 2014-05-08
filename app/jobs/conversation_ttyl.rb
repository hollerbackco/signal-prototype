class ConversationTtyl
  include Sidekiq::Worker

  def perform(membership_id)
    membership = Membership.find(membership_id)
    #membership.seen_without_response

    conversation = membership.conversation

    notify_mqtt(conversation.memberships)
    #membership.others.each do |other|
      #p "notify push to #{other.username}"
      #notify_push(membership, other)
    #end
  end

  private

  def notify_mqtt(memberships)
    memberships.each do |m|
      channel = "user/#{m.user_id}/sync"
      data = [m.to_sync].as_json

      Hollerback::MQTT.delay.publish(channel, data)
    end
  end

  def notify_push(sender_membership, person)
    sender_name = sender_membership.user.also_known_as(for: person)
    text = "#{sender_name}: ttyl"

    badge_count = person.unseen_memberships_count
    Hollerback::Push.delay.send(person.id, {
      alert: text,
      badge_count: badge_count,
      sound: "default",
      content_available: true,
      data: {uuid: SecureRandom.uuid}
    }.to_json)

    data = [sender_membership.to_sync]
    person.devices.android.each do |device|
      Hollerback::GcmWrapper.send_notification([device.token], Hollerback::GcmWrapper::TYPE::SYNC, data)
    end
  end
end
