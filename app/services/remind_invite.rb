class RemindInvite
  def self.run(dryrun=false)
    counter = 0
    self.invites.each do |invite|
      reminderer = self.new(invite, dryrun)
      if reminderer.remind
        counter = counter + 1
      end
    end
    puts "#{counter} invites sent"
  end

  attr_accessor :dryrun, :user, :invite, :invited_user
  def initialize(invite,dryrun=false)
    @dryrun = dryrun
    @invite = invite
    @user = invite.inviter
    @invited_user = User.find_by_phone_normalized(invite.phone)
  end

  def remind
    if remindable?
      if send_sms(invite.phone, message)
        mark_invited(invite)
        mark_keen_invite(user, invite)
      end
      true
    else
      p "skipped"
      false
    end
  end

  def send_sms(phone, message)
    p message, invite.created_at, invite.id
    return false if dryrun
    Hollerback::SMS.send_message phone, message
    true
  end

  def remindable?
    return false if invited_user.present?
    return false if data?
    true
  end

  private

  def data?
    data.present?
  end

  def data
    key = "invite:#{invite.id}:push_invited"
    REDIS.get(key)
  end

  def mark_invited(invite)
    key = "invite:#{invite.id}:push_invited"
    data = ::MultiJson.encode({sent_at: Time.now})
    REDIS.set(key, data)
  end

  def mark_keen_invite(user, invite)
    MetricsPublisher.publish(user, "push:invite_reminder", {invite_id: invite.id, phone: invite.phone})
  end

  def self.invites
    time = Time.now - 3.days
    Invite.pending.where("invites.created_at < ?", time).uniq { |invite| invite.phone }
  end

  def message
    REDIS.get("app:copy:sms_invite_reminder") || "#{user.username} sent you a video on hollerback. download the app here: www.hollerback.co/app"
  end
end
