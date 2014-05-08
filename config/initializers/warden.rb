Warden::Manager.serialize_into_session{|user| user.id }
Warden::Manager.serialize_from_session{|id| User.find(id) }

Warden::Manager.before_failure do |env,opts|
  env['REQUEST_METHOD'] = 'POST'
end

Warden::Strategies.add(:phone_password_code) do
  def valid?
    params['phone'] && params['code'] && params['password']
  end

  def authenticate!
    user = User.authenticate(
        params['phone'],
        params['code'],
        params['password']
        )
    user.nil? ? fail!('Could not log in') : success!(user, 'Successfully logged in')
  end
end

#TODO: Deprecate this ASAP
Warden::Strategies.add(:phone_code) do
  def valid?
    params['phone'] && params['code']
  end

  def authenticate!
    user = User.authenticate_with_code(
        params['phone'],
        params['code'],
    )
    user.nil? ? fail!('Could not log in') : success!(user, 'Successfully logged in')
  end
end


Warden::Strategies.add(:email) do
  def valid?
    params['email'] && params['password']
  end

  def authenticate!
    user = User.authenticate_with_email(
      params['email'].downcase,
      params['password']
      )
    user.nil? ? fail!('Could not log in') : success!(user, 'Successfully logged in')
  end
end

Warden::Strategies.add(:api_token) do
  def authenticate!
    if token = params["access_token"]
      user = User.authenticate_with_access_token(token.strip)
      user.nil? ? fail!('No api key') : success!(user)
    end
  end
end

