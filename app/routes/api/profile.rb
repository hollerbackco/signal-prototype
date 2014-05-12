module SignalApp
  class ApiApp < BaseApp

    #set the first/last name of a user
    post '/me/profile/name' do
      if(!ensure_params(:first_name) and !ensure_params(:last_name))
        return error_json(400, :msg => "missing firstname and last name")
      end

      if(params[:first_name])
        current_user.first_name = params[:first_name]
      end

      if(params[:last_name])
        current_user.last_name = params[:last_name]
      end

      current_user.save

    end

    #set the profile picture of a user
    post '/me/profile/picture' do
      unless ensure_params(params[:profile_pic])
        return error_json(400, :msg => "missing profile_pic parameter")
      end
    end

  end
end