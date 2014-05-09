module SignalApp
  class WebApp < BaseApp
    get '/' do
      #haml :index, layout: false
      user_agent = Signal::UserAgent.new(request.user_agent)

      if user_agent.android?
        return redirect '/beta'
      end

      File.read(File.join('public', 'index.html'))
    end

    get '/about' do
      haml :about
    end

    get '/jobs' do
      haml :jobs
    end

    get '/waitlist' do
      haml :waitlist
    end

    get '/terms' do
      haml :terms
    end

    get '/privacy' do
      haml :privacy
    end

    get '/beta' do
      haml "android/beta".to_sym
    end

    #TODO deprecate, replaced by v/:token
    get '/from/:username/:id' do
      video = Video.find_by_code(params[:id])
      not_found if video.user.username != params[:username]

      @name = video.user.username
      @video_url = video.url
      @thumb_url = video.thumb_url
      haml :video
    end

    get '/android/wait' do
      @post_action = '/android/wait'
      haml 'android/wait'.to_sym, layout: 'layouts/mobile'.to_sym
    end

    post '/android/wait' do
      phone = params[:phone]
      email = params[:email]

      if phone.blank?
        @error_message = 'Please enter a phone number'
        return haml 'android/wait'.to_sym, layout: 'layouts/mobile'.to_sym
      end
      if email.blank?
        @error_message = 'Please enter an email'
        return haml 'android/wait'.to_sym, layout: 'layouts/mobile'.to_sym
      end

      #mark invites as used
      invites = Invite.unscoped.find_all_by_phone(phone)
      invites.each do |invite|
        invite.waitlisted!
      end

      #save the waitlister
      waitlister = Waitlister.where(email: email).first_or_create
      waitlister.phone = phone
      waitlister.save

      haml 'android/confirm'.to_sym, layout: 'layouts/mobile'.to_sym
    end

    get "/thanks" do
      finished('signup_waitlist')
      haml :entries, layout: :pledge
    end

    post '/waitlist' do
      waitlister = Waitlister.new(email: params[:email])
      if waitlister.save
        haml :thanks
      else
        @errors = waitlister.errors
        haml :waitlist
      end
    end

    post '/waitlist.json' do
      waitlister = Waitlister.new(email: params[:email])
      if waitlister.save
        {
          :success => true
        }.to_json
      else
        @errors = waitlister.errors
        {
          :success => false,
          :msg => waitlister.errors.first
        }.to_json
      end
    end

    post '/sms_app_link.json' do
      if phone_string = params["phone"]
        phone = Phoner::Phone.parse(phone_string).to_s
      end

      if phone
        body = "Download hollerback: http://appstore.com/hollerback"
        Signal::SMS.send_message(phone, body)
        {
          :success => true,
          :msg => "Thanks, check the message on your phone"
        }.to_json
      else
        msg = "Invalid phone number"
        {
          :success => false,
          :msg => msg
        }.to_json
      end
    end

    get '/client' do
      haml :client, layout: false
    end
  end
end
