# session routes
module SignalApp
  class ApiApp < BaseApp
    post '/session' do
      logout

      if params.key? 'email' and params.key? 'password'
        authenticate(:email)
        if params.key? "device_token" and !params["device_token"].blank?
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

        data = {
          access_token: device.access_token,
          user: user.as_json.merge(access_token: device.access_token)
        }

        return data.to_json
      else
        unless ensure_params(:phone)
          return error_json 400, msg: "missing required params"
        end

        user = User.find_by_phone_normalized(params["phone"])

        if user
          user.set_verification_code
          user.save
          Signal::SMS.send_message user.phone_normalized, "Signal Code: #{user.verification_code}"
          {
            user: user.as_json
          }.to_json
        else
          not_found
        end
      end
    end

    post '/unauthenticated' do
      $stdout.puts("source=#{settings.environment} measure.unauthenticated=1")
      status 403
      {
        meta: {
          code: 403,
          error_type: "AuthException",
          msg: "Incorrect code or access_token"
        },
        data: nil
      }.to_json
    end

    delete '/session/?:platform?' do
      authenticate(:api_token)
      current_user.devices.where(:access_token => params["access_token"]).destroy_all if current_user
      logout
    end
  end
end
