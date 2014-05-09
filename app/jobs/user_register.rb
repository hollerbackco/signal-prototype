class UserRegister
  include Sidekiq::Worker



  def perform(user_id)
    user = User.find(user_id)

    set_cohort(user)

    accept_invites(user)

    create_messages(user)
    update_conversation_names(user)

    data = {
      memberships: user.memberships.count
    }
    MetricsPublisher.publish_with_delay(user.id, "users:new", data)
    MetricsPublisher.publish_with_delay(user.id, "user:active")
    #WelcomeUser.new(user).run
    Welcome.perform_in(24.hours, user.id)

    begin
      notify_friend_join(user) #this can be done in the background
    rescue Exception => e
      Honeybadger.notify(e, {:error_message => "notify friend join failed"})
    end

    Signal::BMO.say("#{user.username} just signed up")

  end

  private

  def create_messages(user)
    Video.where(:conversation_id => user.conversations.map(&:id)).each do |content|
      sender_membership = Membership.where(conversation_id: content.conversation_id, user_id: content.user_id).first
      receiver_membership = Membership.where(conversation_id: content.conversation_id, user_id: user.id).first
      publisher = ContentPublisher.new(sender_membership)

      if !receiver_membership.messages.find_by_guid(content.guid)
        publisher.publish(content, to: [receiver_membership], analytics: false)
      end
    end
  end

  def update_conversation_names(user)
    Membership.where(:conversation_id => user.conversations.map(&:id)).each do |membership|
      membership.update_conversation_name
    end
  end

  def set_cohort(user)
    begin
      #if cohort is not set, set it
      if (user.cohort.blank?)
        cohorts = Invite.where("phone = ? AND cohort is not null", user.phone_normalized).pluck(:cohort)
        cohorts.concat(EmailInvite.where("email = ? AND cohort is not null", user.email).pluck(:cohort))
        if (cohorts.any?)
          user.cohort = cohorts.last #just pick the last one
          user.save
        end

      end
    rescue Exception => ex
      SignalApp::BaseApp::logger.error "there was a problem extracting the cohort from the invites"
      Honeybadger.notify(ex)
    end

  end

  def accept_invites(user)
    #accept all invites
    Invite.accept_all!(user)
    EmailInvite.accept_all!(user)
  end

  def notify_friend_join(user)
    return unless user
    friends = Contact.where(phone_hashed: user.phone_hashed)

    friends.each do |friend|
      msg = "#{friend.name} just joined"
      MetricsPublisher.publish(friend.user, "friends:join")
      Signal::Push.delay.send(friend.user.id, {
          alert: msg,
          sound: "default",
          content_available: true,
          data: {uuid: SecureRandom.uuid}
      }.to_json)

      tokens =  friend.user.devices.android.map {|device| device.token}
      payload = {:message => msg}
      if(!tokens.empty?)
        Signal::GcmWrapper.send_notification(tokens, Signal::GcmWrapper::TYPE::NOTIFICATION, payload)
      end

      # Mail.deliver do
      #   to friend.user.email
      #   from 'no-reply@hollerback.co'
      #   subject "#{friend.name} just joined Signal"
      #
      #   text_part do
      #     body "Just wanted to let you know that #{friend.name} just joined Signal! Send them a message."
      #   end
      # end

    end
  end
end
