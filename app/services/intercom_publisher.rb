class IntercomPublisher
  include Sidekiq::Worker

  class Method
    CREATE = "create"
    UPDATE = "update"
  end


  def perform(user_id, method, user_agent, user_ip)

    user = User.find(user_id)
    case method
      when Method::CREATE
        create_user(user, user_agent, user_ip)
      when Method::UPDATE
        update_user(user, user_agent, user_ip)
    end

  end

  def create_user(user, user_agent, user_ip)
    payload = get_user_payload(user, user_agent, user_ip)
    Intercom::User.create(payload)
  end

  def update_user(user, user_agent, user_ip)
    payload = get_user_payload(user, user_agent, user_ip)
    Intercom::User.create(payload)
    impression(user, user_agent)
  end

  def impression(user, user_agent)
    Intercom::Impression.create(:email => user.email, :user_agent => user_agent)
  end

  def get_user_payload(user, user_agent, user_ip)
    {
        :email => user.email,
        :created_at => user.created_at.to_f,
        :last_seen_user_agent => user_agent,
        :last_request_at => user.last_active_at.to_f,
        :last_seen_ip => user_ip,
        :custom_data => {
            :video_count => user.videos.count,
            :text_count => (user.respond_to?('texts') ? user.texts.count : 0),
            :invite_count => user.invites.count,
            :cohort => user.cohort,
            :last_app_version => user.last_app_version
        }
    }
  end

end
