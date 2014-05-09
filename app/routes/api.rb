module SignalApp
  class ApiApp < BaseApp
    before do
      content_type 'application/json'
    end

    configure do
      use Warden::Manager do |config|
        config.failure_app = SignalApp::ApiApp

        config.scope_defaults :default,
          strategies: [:api_token, :password],
          action: '/unauthenticated',
          store: false
      end
    end
  end
end
