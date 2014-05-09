require 'will_paginate'
require 'will_paginate/active_record'
require 'sinatra/multi_route'

module SignalApp
  class BaseApp < ::Sinatra::Base

    register ::Sinatra::ActiveRecordExtension
    register WillPaginate::Sinatra

    set :app_root, File.expand_path(".")

    # Setup db
    set :database, "#{ENV["DATABASE_URL"]}?pool=#{ENV["DB_POOL"] || 10}"
    set :redis, ENV["REDISTOGO_URL"]

    dalli = if ENV["MEMCACHIER_SERVERS"]
      Dalli::Client.new( ENV['MEMCACHIER_SERVERS'],
                          :username => ENV['MEMCACHIER_USERNAME'],
                          :password => ENV['MEMCACHIER_PASSWORD'],
                          :expires_in => 1.day)
    else
      Dalli::Client.new
    end
    set :cache, dalli

    def self.logger
      @logger ||= Logger.new(STDOUT)
    end

    # i18n
    configure do
      enable :logging

      ActiveRecord::Base.include_root_in_json = false
      I18n.load_path = Dir[File.join(settings.app_root, 'config', 'locales', '*.yml')]
    end

    def self.load_lib
      %w[lib].each do |dir|
        Dir.glob("./#{dir}/**/*.rb").each do |relative_path|
          require relative_path
        end
      end
    end

    def self.load_config
      # Setup lib
      %w[lib config/initializers].each do |dir|
        Dir.glob("./#{dir}/**/*.rb").each do |relative_path|
          require relative_path
        end
      end
      # Setup app
      require File.expand_path('./app/app')
    end

  end
end

SignalApp::BaseApp.load_lib
SignalApp::BaseApp.helpers ::Sinatra::Warden::Helpers
SignalApp::BaseApp.helpers ::Sinatra::CoreHelpers
SignalApp::BaseApp.helpers WillPaginate::Sinatra::Helpers
SignalApp::BaseApp.register Sinatra::MultiRoute
#SignalApp::BaseApp.register ::Sinatra::ActiveRecordExtension
SignalApp::BaseApp.load_config
