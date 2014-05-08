ruby "2.0.0"
source 'http://rubygems.org'
source 'http://gemcutter.org'

gem 'rake'

#server
gem 'unicorn'
gem 'sinatra', :require => 'sinatra/base'
gem 'sinatra-contrib'
gem 'rack-reverse-proxy', :require => 'rack/reverse_proxy'
gem 'rack-parser', :require => 'rack/parser'

#database
gem 'activerecord'
gem 'activerecord-postgres-hstore'
gem 'sinatra-activerecord'
gem 'pg'
gem 'redis'
gem 'dalli'
gem 'upsert'

#environment
gem 'dotenv'

#model
gem 'awesome_nested_set'
gem 'will_paginate'

#views
gem 'haml'
gem 'redcarpet'

#authentication
gem 'warden'

#storage
gem 'aws-sdk'

#fake sqs for local testing
gem 'fake_sqs'

#messaging
gem 'phone'
gem 'twilio-ruby'
gem 'houston'
gem 'gcm'
gem 'mqtt'
gem 'mail'

#utils
gem 'multi_json'
gem 'split', :require => 'split/dashboard'
gem 'split-analytics', :require => 'split/analytics'
gem 'bcrypt-ruby'
gem 'time-lord'
gem 'i18n'
gem 'em-http-request', '~> 1.0'
gem 'celluloid'
gem 'heroku'
gem 'intercom'

#background
gem 'slim'
gem 'sidekiq'
gem 'streamio-ffmpeg'
gem 'mini_magick'

#analytics
gem 'keen'
gem 'newrelic_rpm'
gem 'honeybadger'

#assets
gem 'therubyracer', :require => 'v8'
gem 'sprockets'
gem 'sprockets-helpers'
gem 'sprockets-sass'
gem 'coffee-script'
gem 'compass'
gem 'handlebars_assets'

group :development do
  gem 'rerun'
  gem 'rb-fsevent'
  gem 'tux'
  gem 'guard-sprockets2'
  gem 'yui-compressor'
  gem 'uglifier'
  gem 'reek'
  gem 'flay'
  gem 'thin'
end

group :test do
  gem 'rspec'
  gem 'sqlite3'
  gem 'database_cleaner'
  gem 'sms-spec', :git => 'https://github.com/hollerbackco/sms-spec.git', :branch => 'sms-spec'
  gem 'factory_girl'
  gem 'ffaker'
end

group :test, :development do
  gem 'guard-rspec'
  gem 'em-rspec'
end
