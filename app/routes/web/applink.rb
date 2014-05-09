module SignalApp
  class WebApp < BaseApp

    APP_DOWNLOAD_LINK = ""
    ENTERPRISE_APP_DOWNLOAD_LINK = ""
    ALLOWED_LOCALES = ["AU", "NZ", "CA"]
    INVITE_COHORTS = ["psiu", "vip", "friendsvip", "vipnyc", "nycvip", "usc", "wes", "wesley", "socialsignin"]

    helpers do
      def sms_download_notification(name)
        if Sinatra::Base.production? and ! params.key? :test
          Signal::SMS.send_message "+13033595357", "[ios] #{name} was sent to the appstore"
        end
      end

      def ios?
        user_agent = Signal::UserAgent.new(request.user_agent)
        user_agent.ios?
      end

      def android?
        user_agent = Signal::UserAgent.new(request.user_agent)
        user_agent.android?
      end
    end

    get '/app' do
      redirect "hollerback://"
    end

    get '/install' do
      redirect_url = ""
      if(android?)
        redirect_url = '/beta'
      elsif(ios?)
        url = URI.escape("https://s3.amazonaws.com/hb-distro/SignalApp-download.plist")
        redirect_url = "itms-services://?action=download-manifest&url=#{url}"
      else
        redirect_url = "/waitlist"
      end

      redirect redirect_url
    end

    get '/invite/:cohort' do
      cohort = params[:cohort]
      source = params[:src]
      if(INVITE_COHORTS.include?(cohort))
        MetricsPublisher.delay.publish_delay("invite:click", {:cohort => cohort, :source => source})
        redirect "/beta/test/#{cohort}"
      else
        redirect "/beta/test/download"
      end
    end

    ['/download','/invite', '/v/:token', '/usc'].each do |location|
      get location do
        if android?
          redirect '/beta'
        else
          if location == "/usc"
            MetricsPublisher.delay.publish_delay("email:usc:app_visit")
          end

          locale = Timeout::timeout(5) { Net::HTTP.get_response(URI.parse('http://api.hostip.info/country.php?ip=' + request.remote_ip )).body } rescue "US"
          available = ALLOWED_LOCALES.detect { |allowed| locale == allowed }
          if(true)
            url = APP_DOWNLOAD_LINK
          else
            url = "/waitlist"
          end
          redirect url
        end
      end
    end

    get '/beta/test/:branch' do
      redirect_url = ""
      if(android?)
        redirect_url = '/beta'
      elsif(ios?)
        url = URI.escape("https://s3.amazonaws.com/hb-distro/SignalApp-#{params[:branch]}.plist")
        redirect_url = "itms-services://?action=download-manifest&url=#{url}"
      else
        redirect_url = "/waitlist"
      end

      redirect redirect_url
    end

    get '/beta/:party' do
      app_link = AppLink.where(slug: params[:party], segment: "ios").first_or_create
      if params[:party] == "teamhollerback"
        url = URI.escape("https://s3.amazonaws.com/hb-distro/SignalApp-staging.plist")
        url = "itms-services://?action=download-manifest&url=#{url}"
      elsif app_link.usable?
        #sms_download_notification(params[:party])
        app_link.increment!(:downloads_count)

        #to enterprise build
        #url = URI.escape("https://s3.amazonaws.com/hb-distro/SignalApp-master.plist")
        #url =  "itms-services://?action=download-manifest&url=#{url}"

        url = APP_DOWNLOAD_LINK
      else
        url = "/"
      end
      redirect url
    end

    #get '/android/:party' do
      #party = params[:party]

      #if Sinatra::Base.production? and ! params.key? :test
        #Signal::SMS.send_message "+13033595357", "[android] #{party} visited the beta page"
      #end

      #app_link = AppLink.where(slug: party, segment: "android").first_or_create

      #if params[:party] == "teamhollerback"
        #app_link.increment!(:downloads_count)
        #url = URI.escape("https://s3.amazonaws.com/hollerback-app-dev/distro/SignalAndroid-Stage.apk")
        #redirect url
      #elsif app_link.usable?
        #app_link.increment!(:downloads_count)
        #url = URI.escape("https://s3.amazonaws.com/hollerback-app-dev/distro/SignalAndroid.apk")
        #redirect url
      #else
        #redirect "/"
      #end
    #end
  end
end
