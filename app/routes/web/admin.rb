module HollerbackApp
  class WebApp < BaseApp
    def http_authorized?
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [ENV["ADMIN_USERNAME"], ENV["ADMIN_PASSWORD"]]
    end

    def http_protected
      unless http_authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Oops... we need your login name & password\n"])
      end
    end

    before '/madmin*' do
      http_protected
    end

    post '/madmin/app/version' do
      if params[:version]
        REDIS.set("app:current:version", params[:version])
        "success"
      else
        "please specify version number"
      end
    end

    get '/madmin/settings' do
      @sms_invite_reminder = REDIS.get("app:copy:sms_invite_reminder")
      @min_ios_version_for_force_upgrade = REDIS.get("app:copy:min_ios_version_for_force_upgrade")
      @min_beta_ios_version_for_force_upgrade = REDIS.get("app:copy:min_beta_ios_version_for_force_upgrade")
      @invite_reminder_flag = REDIS.get("app:copy:invite_reminder_flag")
      haml "admin/settings".to_sym, layout: "layouts/admin".to_sym
    end

    post '/madmin/settings' do
      if params.any?
        params.each do |key, value|
          REDIS.set("app:copy:#{key}", value)
        end
      end
      redirect "/madmin/settings"
    end

    get '/madmin' do
      @broken = Video.where(:filename => nil)
      @contents = Content.paginate(:page => params[:page], :per_page => 20)
      haml "admin/index".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/videos' do
      @videos = Video.paginate(:page => params[:page], :per_page => 20)
      haml "admin/index".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/exceptions' do
      @entries = Keen.extraction("app:exceptions", :timeframe => "today")
      #create a map of the entries
      entry_map = []
      @entries.each do |entry|
        item = entry_map.detect { |item| item["exception"] == entry["exception"] }
        if item
          item["count"] = item["count"] + 1
          unless item["app_version"].detect { |saved_version| saved_version == entry["app_ver"] }
            item["app_version"] << entry["app_ver"]
          end

          unless item["user_id"].detect { |saved_id| saved_id == entry["user_id"] }
            item["user_id"] << entry["user_id"]
          end
        else
          entry_map << {"exception" => entry["exception"], "count" => 1, "app_version" => [entry["app_ver"]], "user_id" => [entry["user_id"]]}
        end
      end
      @entries = entry_map
      haml "admin/ios_app_exceptions".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/conversations/:id' do
      @conversation = Conversation.find(params[:id])
      @members = @conversation.members
      @messages = @conversation.memberships.first.messages.reorder("messages.created_at DESC")

      haml "admin/memberships".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/users' do
      @users = User
      if params.key?("android")
        @users = User.android
      end
      @users = @users.order("created_at DESC").includes(:memberships, :messages, :devices)
      .paginate(:page => params[:page], :per_page => 50)

      haml "admin/users".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/users/find' do
      user_info = params[:username_or_email]
      @user = nil
      begin
        @user = User.find_by_username!(user_info)
      rescue

      end

      if @user.blank?
        begin
          @user = User.find_by_email!(user_info)
        rescue
          return "'#{user_info}' not found!"
        end
      end

      @memberships = @user.memberships
      @messages = @user.messages
      haml "admin/users/show".to_sym, layout: "layouts/admin".to_sym
    end


    get '/madmin/users/:id' do
      @user = User.includes(:memberships, :messages).find(params[:id])
      @memberships = @user.memberships
      @messages = @user.messages.order("created_at DESC")
      #@users = User.order("created_at ASC").includes(:memberships, :messages, :devices).all
      haml "admin/users/show".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/users/:id/edit' do
      @user = User.find(:id)
      haml "admin/users/edit".to_sym, layout: "layouts/admin".to_sym
    end

    put '/madmin/users/:id' do
      @user = User.find(:id)
      if @user.update_attributes(params[:user])
        redirect "/madmin/users/#{@user.id}/edit"
      else
        haml "admin/users/edit".to_sym, layout: "layouts/admin".to_sym
      end
    end

    get '/madmin/invites' do
      @invites = Invite.order("created_at DESC").includes(:inviter).paginate(:page => params[:page], :per_page => 50)
      haml "admin/invites".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/metrics' do
      @app_links = AppLink.all
      haml "admin/stats".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/app_links' do
      @app_links = AppLink.all
      haml "admin/app_links".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/waitlist' do
      @waitlisters = Waitlister.all
      haml "admin/invite_requests".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/stats' do
      stats = Hollerback::Statistics.new
      {
          users_count: stats.users_count,
          conversations_count: stats.conversations_count,
          videos_count: stats.videos_sent_count,
          received_count: stats.videos_received_count
      }.to_json
    end
  end
end
