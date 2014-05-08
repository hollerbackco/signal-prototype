Honeybadger.configure do |config|
  config.api_key = ENV['HONEYBADGER_API_KEY']
end

module HollerbackApp
  class BaseApp < ::Sinatra::Base
    use Honeybadger::Rack
  end
end
