module HollerbackApp
  class BaseApp < Sinatra::Base
    configure do
      Hollerback::GcmWrapper::init #initialize gcm
    end
  end
end
