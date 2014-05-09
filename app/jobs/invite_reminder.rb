class InviteReminder
  include Sidekiq::Worker

  def perform(invite_id)

    begin
      invite = Invite.find(invite_id)
      unless invite.accepted?
        inviter = User.find(invite.inviter_id)


        unless(invite.conversation.blank?)
          message = "hi. #{inviter.username} sent you a message and they're waiting for you to see it on signal. you can download it here: http://www.hollerback.co/download"
          invite_type = "implicit"
        else
          message = "hi. #{inviter.username} wants to send you messages on signal. they're waiting for you here: http://www.hollerback.co/download"
          invite_type = "explicit"
        end

        Signal::SMS.send_message(invite.phone, message)

        unless invite.tracked

          data = {
              invites: [invite.phone],
              already_invited: []
          }
          MetricsPublisher.publish_user_metric(inviter, "users:invite:#{invite_type}", data)
          invite.tracked = true
        end
        invite.save
        data = { phone: invite.phone }
        MetricsPublisher.publish_delay("invite:reminder", data)
      end
    rescue Exception => ex
      Honeybadger.notify(ex)
    end
  end
end