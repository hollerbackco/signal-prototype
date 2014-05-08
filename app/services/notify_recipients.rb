module Hollerback
  class NotifyRecipients
    attr_accessor :messages

    def initialize(messages, opts={})
      @messages = messages
    end

    def run
      messages.each do |message|
        recipient = message.membership.user
        unless message.sender?
          notify_push message, recipient
        end
        notify_mqtt message, recipient
      end
    end

    private

    def notify_mqtt(message, person)
      channel = "user/#{person.id}/sync"
      Hollerback::MQTT.delay.publish(channel, {})
    end

    def notify_push(message, person)
      membership = message.membership
      badge_count = person.unseen_memberships_count

      # if(message.message_type == Message::Type::TEXT)
      #   alert_msg = "#{message.sender_name}: #{message.content["text"]}"
      # else
      if(membership.conversation.members.count > 2)
        alert_msg = "#{message.sender_name} sent a message"
      else
        alert_msg = "#{message.sender_name} sent you a message"
      end

      #end

      Hollerback::Push.delay.send(person.id, {  #are we sending it to apple anyways?
        alert: alert_msg,
        badge: badge_count,
        sound: "default",
        content_available: true,
        data: {uuid: SecureRandom.uuid, conversation_id: membership.id}
      }.to_json)

      if(message.message_type == Message::Type::TEXT)
        alert_msg = "#{message.sender_name}: #{message.content["text"]}"
        person.devices.android.each do |device|
          res = Hollerback::GcmWrapper.send_notification([device.token],                     #tokens
                                                         Hollerback::GcmWrapper::TYPE::NOTIFICATION, #type
                                                         {:message => alert_msg},                                #payload
                                                         collapse_key: "new_message")        #options

          puts res
        end
      else
        person.devices.android.each do |device|
          res = Hollerback::GcmWrapper.send_notification([device.token],                     #tokens
                                                         Hollerback::GcmWrapper::TYPE::SYNC, #type
                                                         nil,                                #payload
                                                         collapse_key: "new_message")        #options

          puts res
        end
      end

    end
  end
end
