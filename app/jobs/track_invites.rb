class TrackInvites
  include Sidekiq::Worker

  def perform(user_id, phones)
    user = User.find(user_id)

    untracked_invites = Invite.where("phone IN (?) AND inviter_id = ? AND tracked = ?", phones, user_id, false)

    actual_invites = []
    untracked_invites.each do |invite|
      unless Invite.where("phone = ? AND tracked = ?", invite.phone, true).any?
        actual_invites << invite.phone
      end
      invite.tracked = true
      invite.save
    end

    data = {
        invites: actual_invites,
        already_invited: (phones - actual_invites)
    }

    p "metric: users:invite:implicit: " + data.to_s

    MetricsPublisher.publish(user, "users:invite:implicit", data)

    if(actual_invites.any?)
      Signal::BMO.say("#{user.username} invited #{actual_invites.count} people through a conversation")
    end

  end
end