module SignalApp
  class ApiApp < BaseApp
    post '/me/users/:id/mute' do
      user = User.find(params[:id])
      current_user.mute!(user)
      success_json data: nil
    end

    post '/me/users/:id/unmute' do
      user = User.find(params[:id])
      current_user.unmute!(user)
      success_json data: nil
    end

    post '/me/users/muted' do
      muted = current_user.muted_users
      success_json data: muted
    end
  end
end
