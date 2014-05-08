# register routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/register' do
      unless ensure_params(:email, :password, :username, :phone)
        return error_json 400, msg: "Missing required params"
      end
      begin
        user = User.find_by_email(params[:email])
        if user and user.verified?
          return error_json 400, msg: "Email is taken"
        end

        if user.present?
          # make sure the passwords match
          user = User.authenticate_with_email(params[:email], params[:password])
          raise ActiveRecord::RecordNotFound if user.blank?
        else
          user = User.new({email: params[:email], password: params[:password]})
        end

        user.phone = params[:phone]
        user.phone_hashed = params[:phone_hashed]
        user.username = params[:username]
        user.set_verification_code

        #extract cohort info if any
        unless params[:cohort].blank?
          #the cohort comes as a url parse it
          cohort = params[:cohort]
          begin
            cohort = URI(cohort).path.split('/').last
            if (cohort != "download")
              user.cohort = cohort
            end
          rescue Exception => ex
            logger.error ("couldn't extract cohort: #{cohort}")
            Honeybadger.notify(ex)
          end
        end

        if user.save
          # send a verification code
          Hollerback::SMS.send_message user.phone_normalized, "Hollerback Code: #{user.verification_code}"

          {
              user: user.reload.as_json
          }.to_json
        else
          error_json 400, for: user
        end
      rescue ActiveRecord::RecordNotFound
        error_json 400, msg: "Email is taken"
      end
    end

    post '/verify' do
      unless ensure_params(:phone, :code)
        return error_json 400, msg: "Missing required params"
      end

      user = User.find_by_phone(params[:phone])
      is_new = (user.blank? || user.new?) ? true : false

      if(params['password'])
        authenticate(:phone_password_code)
      else
        #TODO: Deprecate this ASAP
        authenticate(:phone_code)
      end


      #authenticate(:password)
      # remove all devices with device_token that is not blank
      if params.key "device_token" and !params["device_token"].blank?
        devices = Device.where("token" => params["device_token"])
        devices.destroy_all
      end

      if params.key? "device_id"
        if device = user.devices.find_by_device_key(params["device_id"])
          device.token = params["device_token"]
          device.save
        end
      end
      if device.blank?
        device = user.device_for(params['device_token'], params['platform'])
      end

      if (is_new)
        registrar = UserRegister.new
        registrar.perform(device.user.id)

        #track active user
        TrackUserActive.perform_async(device.access_token)

        #create the intercom user
        IntercomPublisher.perform_async(user.id, IntercomPublisher::Method::CREATE, request.user_agent, request.ip)
      end

      {
          access_token: device.access_token,
          user: user.reload.as_json.merge(access_token: device.access_token)
      }.to_json
    end

    post '/email/available' do

      api_version = request.accept[0].to_s
      if (api_version == HollerbackApp::ApiVersion::V1)
        email = params[:email]
        free = true

        if email.blank? || !email.match(User::VALID_EMAIL_REGEX)
          msg = "invalid email"
          free = false
        elsif !User.find_by_email(params[:email]).blank?
          msg = "email taken"
          free = false
        end

        return success_json data: {:free => free, :message => msg}
      end

      free = User.find_by_email(params[:email]).blank?

      return success_json data: free
    end

    post '/waitlist' do
      waitlister = Waitlister.new(email: params[:email])

      if waitlister.save
        {
            data: waitlister.to_json
        }
      else
        error_json 400, msg: waitlister.errors
      end
    end
  end
end
