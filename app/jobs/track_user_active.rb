class TrackUserActive
  include Sidekiq::Worker

  def perform(access_token)
    user = User.authenticate_with_access_token(access_token)

    if(user)
      MetricsPublisher.publish_user_metric(user, "user:active")
    end
  end
end