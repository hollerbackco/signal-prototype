module HollerbackApp
  class BaseApp < Sinatra::Base
    configure :development, :staging, :test do
      pemfile = File.join(app_root, 'config', 'apns', 'apns_enterprise_dev.pem')
      Hollerback::Push.configure(pemfile, false, app_root)
    end

    configure :production do
      require 'newrelic_rpm'
      pemfile = File.join(app_root, 'config', 'apns', 'apns_enterprise_prod.pem')
      Hollerback::Push.configure(pemfile, true, app_root)
    end
  end
end
