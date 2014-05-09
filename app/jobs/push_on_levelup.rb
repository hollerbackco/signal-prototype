class PushOnLevelUp
  include Sidekiq::Worker

  def perform(user_id, message_count)
    #look up the users friends on hollerback
    begin
      user = User.find(user_id)
      friends = Contact.where(:phone_hashed => user.phone_hashed)

      friends.each do |friend|
        msg = "#{friend.name} sent #{message_count} videos to friends and family"

        Signal::Push.delay.send(friend.user.id, {
                                                  alert: msg,
                                                  sound: "default",
                                                  content_available: false,
                                                  data: {uuid: SecureRandom.uuid}
        }.to_json)

        tokens =  friend.user.devices.android.map {|device| device.token}
        payload = {:message => msg}
        if(!tokens.empty?)
          Signal::GcmWrapper.send_notification(tokens, Signal::GcmWrapper::TYPE::NOTIFICATION, payload)
        end
      end

    rescue
      logger.error "couldn't send level up push"
    end

  end
end
