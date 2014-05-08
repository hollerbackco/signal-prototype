# Reset Password Routes
module HollerbackApp
  class WebApp < BaseApp
    helpers do
      def create_token(user_id)
        token = SecureRandom.urlsafe_base64
        key = "change_password:#{token}"
        data = ::MultiJson.encode({user_id: user_id})
        REDIS.set(key, data)
        token
      end

      def get_token_data(token)
        unparsed_data = REDIS.get("change_password:#{token}")
        return nil if unparsed_data.blank?

        ::MultiJson.decode(unparsed_data)
      end

      def expire_token(token)
        REDIS.del("change_password:#{token}")
      end
    end

    get '/forgotpw' do
      haml 'password/forgot'.to_sym, layout: 'layouts/mobile'.to_sym
    end

    post '/forgotpw' do
      if params[:email].blank?
        @error_message = "please enter an email"
        return haml 'password/forgot'.to_sym, layout: 'layouts/mobile'.to_sym
      end
      user = User.find_by_email(params[:email].downcase)
      if user.blank?
        @error_message = "nobody by that email exists"
        return haml 'password/forgot'.to_sym, layout: 'layouts/mobile'.to_sym
      end

      token = create_token(user.id)
      url = absolute_url("/changepw/" + token)
      Mail.deliver do
        to user.email
        from 'no-reply@hollerback.co'
        subject 'Hollerback Password Change'

        text_part do
          body "Change your password here:\n #{url}"
        end
      end

      haml 'password/confirmation'.to_sym, layout: 'layouts/mobile'.to_sym
    end

    get '/changepw/:token' do
      unless data = get_token_data(params[:token])
        return haml 'password/expired'.to_sym, layout: 'layouts/mobile'.to_sym
      end
      begin
        @user = User.find(data["user_id"])
        @post_action = "/changepw/#{params[:token]}"

        haml 'password/change'.to_sym, layout: 'layouts/mobile'.to_sym
      rescue ActiveRecord::RecordNotFound
        return haml 'password/expired'.to_sym, layout: 'layouts/mobile'.to_sym
      end
    end

    post '/changepw/:token' do
      unless data = get_token_data(params[:token])
        return haml 'password/expired'.to_sym, layout: 'layouts/mobile'.to_sym
      end
      if params[:password].blank? or params[:password] != params[:confirm]
        @error_message = "passwords do not match"
        return haml 'password/change'.to_sym, layout: 'layouts/mobile'.to_sym
      end

      begin
        user = User.find(data["user_id"])
        user.password = params[:password]

        if user.save
          expire_token(params[:token])
          redirect "hollerback://"
          #redirect to app
        else
          p user.errors
          @error_message = "passwords do not match"
          haml 'password/change'.to_sym, layout: 'layouts/mobile'.to_sym
        end
      rescue ActiveRecord::RecordNotFound
        return haml 'password/expired'.to_sym, layout: 'layouts/mobile'.to_sym
      end
    end
  end
end
