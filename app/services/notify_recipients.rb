module Signal
  class NotifyRecipients

    def self.on_new_message(messages)
      messages.each do |message|
        recipient = message.membership.user
        unless message.sender? || !message.membership.following?
          NotifyRecipients.notify_push message.membership, recipient, message.content['text'], message.sender_name
        end
        #notify_mqtt message, recipient
      end
    end

    def self.on_new_conversation(memberships, sender)
      memberships.each do |membership|
        NotifyRecipients.notify_push(membership, membership.user, membership.conversation.name, sender.also_known_as(:for => membership.user))
      end
    end

    private

    def notify_mqtt(message, person)
      channel = "user/#{person.id}/sync"
      Signal::MQTT.delay.publish(channel, {})
    end

    def self.notify_push(membership, recipient, push_copy, sender_name)
      badge_count = recipient.unseen_memberships_count

      if (membership.conversation.members.count > 2)
        alert_msg = "#{sender_name} sent a message"
      else
        alert_msg = "#{sender_name} sent you a message"
      end

      Signal::Push.delay.send(recipient.id, {#are we sending it to apple anyways?
                                          alert: alert_msg,
                                          badge: badge_count,
                                          sound: "default",
                                          content_available: true,
                                          data: {uuid: SecureRandom.uuid, conversation_id: membership.id}
      }.to_json)

      alert_msg = "#{sender_name}: #{push_copy}"
      recipient.devices.android.each do |device|
        res = Signal::GcmWrapper.send_notification([device.token], #tokens
                                                   Signal::GcmWrapper::TYPE::NOTIFICATION, #type
                                                   {:message => alert_msg}, #payload
                                                   collapse_key: "new_message") #options

        puts res
      end
    end


  end
end
