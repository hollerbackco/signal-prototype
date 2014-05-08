class Welcome
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)

    WelcomeUser.new(user).run
  end
end
