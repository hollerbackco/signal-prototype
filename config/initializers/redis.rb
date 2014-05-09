uri = URI.parse(SignalApp::BaseApp.settings.redis)
REDIS = ::Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

Split.redis = REDIS
