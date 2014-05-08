class MetricsPublisher
  def self.publish(actor, topic, data={})
    if actor.is_a? User
      data = data.merge({user: actor.meta})
    end

    MetricsPublisher.delay.publish_with_delay(actor.id, topic, data)
  end

  #immediately publishes a user metric
  def self.publish_user_metric(user, topic, data={})
    if (user.is_a? User)
      data = data.merge({user: user.meta})
    else
      p "[warning|MetricsPublisher] ignoring. no user."
    end

    begin
      Keen.publish(topic, data)
    rescue Exception => ex
      Honeybadger.notify(ex)
      puts "[error|MetricsPublisher] keen publishing error"
    end
  end

  def self.publish_with_delay(actor_id, topic, data={})
    begin
      actor = User.find(actor_id)
      data = data.merge({user: actor.meta})
    rescue ActiveRecord::RecordNotFound
      puts "[error|MetricsPublisher] user does not exist"
      return
    end

    begin
      Keen.publish(topic, data)
    rescue Exception => ex
      Honeybadger.notify(ex)
      puts "[error|MetricsPublisher] keen publishing error"
    end
  end

  def self.publish_delay(topic, data={})
    Keen.publish(topic, data)
  end
end
