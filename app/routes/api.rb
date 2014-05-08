module HollerbackApp
  class ApiApp < BaseApp
    before do
      content_type 'application/json'
    end

    configure do
      use Warden::Manager do |config|
        config.failure_app = HollerbackApp::ApiApp

        config.scope_defaults :default,
          strategies: [:api_token, :password],
          action: '/unauthenticated',
          store: false
      end
    end
  end
end
