class RemindInactive
  def self.run(dryrun=false)
    counter = 0
    User.find_each do |user|
      reminderer = self.new(user: user, dryrun: dryrun)
      if reminderer.remind
        counter = counter + 1
      end
    end
    p "#{counter} users"
  end

  attr_accessor :dryrun, :user, :user_reminders
  def initialize(opts={})
    @dryrun = opts[:dryrun] || false
    @user = opts[:user]
    @user_reminders = UserReminders.new(user)
  end

  def remind
    if remindable?
      sender_name = remindable_message.sender_name

      if send_push(user, sender_name)
        user_reminders.create(remindable_message)
        track_metrics(user, remindable_message)
      end

      true
    else
      false
    end
  end

  def send_push(user, message)
    p user.username, message
    return false if dryrun
    p "doing the real thing"
    Signal::Push.send(nil,user.id, {
      alert: message,
      sound: "default"
    }.to_json)
    return true
  end

  def remindable?
    # user must be inactive
    three_days_ago = Time.now - 3.days
    return false if user.active?(three_days_ago)

    # user must have a message that is
    # available to be used in the reminder
    return false if remindable_message.blank?

    # user must not have been reminded in the last
    # 3 days
    if (user.active?(three_days_ago)) and
      (user_reminders.last_reminder_at < user.last_active_at)
      return true
    end

    ten_days_ago = Time.now - 10.days
    if (user.active?(ten_days_ago)) and
      (Time.now - user_reminders.last_reminder_at > 7.days)
      return true
    end

    false
  end

  # a message that has not been seen and has not been
  # already used in a reminder
  def remindable_message
    return @remindable_message if @remindable_message.present?

    messages = user.unseen_messages
    messages = messages.select do |message|
      !user_reminders.reminded?(message)
    end

    @remindable_message = messages.first
  end

  def track_metrics(user, message)
    MetricsPublisher.publish(user, "push:message_reminder", {message_id: message.id})
  end

  class UserReminders
    attr_accessor :user

    def initialize(user)
      @user = user
    end

    def last_reminder_at

      data["sent_at"] ? Time.parse(data["sent_at"]) : (Time.now - 1.year)
    end

    def message_ids
      return [] if data.blank?

      data["message_ids"] || [data["message_id"]].compact
    end

    def reminded?(message)
      return true if message.blank?

      if message_ids.include?(message.id)
        return true
      end

      false
    end

    def create(message)
      key = "user:#{user.id}:push_remind"

      messages = message_ids
      messages << message.id
      messages = clean(messages)

      new_data = ::MultiJson.encode({message_ids: messages, sent_at: Time.now})
      REDIS.set(key, new_data)
    end

    def clean(messages)
      unseen_ids = user.unseen_messages.map(&:id)
      messages & unseen_ids
    end

    def reset
      key = "user:#{user.id}:push_remind"
      REDIS.del(key)
    end

    private

    def data
      data = REDIS.get("user:#{user.id}:push_remind")
      if data
        ::MultiJson.decode(data)
      else
        {}
      end
    end
  end
end
