module SignalApp
  class BaseApp < Sinatra::Base
    configure do
      Signal::GcmWrapper::init #initialize gcm
    end
  end
end
