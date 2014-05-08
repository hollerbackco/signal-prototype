require File.expand_path('./config/environment')
require 'sidekiq/web'

use Rack::MethodOverride
use Rack::ReverseProxy do
  # Set :preserve_host to true globally (default is true already)
  reverse_proxy_options :preserve_host => false

  #Forward the path /test* to http://example.com/test*
  reverse_proxy '/blog', 'http://ec2-72-44-44-118.compute-1.amazonaws.com/blog'
end

# gzip
use Rack::Deflater
use Rack::CompressedRequests
# parse json
use Rack::Parser, :parsers => {
    'application/json' => proc {|body| ::MultiJson.decode body}
}

map '/api' do
  run HollerbackApp::ApiApp
end

map '/sidekiq' do
  run ::Sidekiq::Web
end

::Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  username == 'jnoh' && password == 'watchthis'
end

map HollerbackApp::WebApp.settings.assets_prefix do
  run HollerbackApp::WebApp.sprockets
end

map '/' do
  run HollerbackApp::WebApp
end
