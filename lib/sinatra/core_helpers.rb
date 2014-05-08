module Sinatra
  module CoreHelpers

    WEEK_IN_SECONDS = 604800

    def t(*args)
      I18n.t(*args)
    end

    def logger
      return @logger if @logger
      @logger = HollerbackApp::BaseApp.logger
      @logger.formatter = proc do |severity, datetime, progname, msg|
        user_info = (logged_in? ? "#{user.username}:#{user.id}" : "anon_user")
        "[#{datetime}|#{progname}|#{user_info}] #{msg}\n"
      end
      @logger
    end

    def parse_phones(phones, country_code, area_code)
      phones.map do |phone|
        Phoner::Phone.parse(phone, country_code: country_code, area_code: area_code).to_s
      end.compact.uniq
    end

    def absolute_url(url)
      if Sinatra::Base.production?
        url = "http://www.hollerback.co#{url}"
      else
        url = "http://lit-sea-1934.herokuapp.com#{url}"
      end
    end

    def create_video_share_url(video, phone)
      value = [video.id, phone].to_json
      token = shortlink_token
      key = "links:#{token}"

      REDIS.set(key, value)
      REDIS.expire(key, WEEK_IN_SECONDS)

      url = "http://www.hollerback.co/v/#{token}"
    end

    def shortlink_token
      (Time.now.to_i + rand(36**8)).to_s(36)
    end

    # checks the params hash for a single argument as both !nil and !empty
    def ensure_param(arg)
      params[arg.to_s].present?
    end

    # checks an array of params from the params hash
    def ensure_params(*args)
      return catch(:truthy) {
        args.each do |arg|
          unless ensure_param arg
            throw(:truthy, false)
          end
        end

        throw(:truthy, true)
      }
    end

    def success_json(opts={})
      data = opts.delete(:data)
      meta = {code: 200}
      if meta_add = opts.delete(:meta)
        meta = meta.merge meta_add
      end

      {
        meta: meta,
        data: data
      }.to_json
    end

    def error_json(error_code, options = {})
      options = options.symbolize_keys

      return unless error_code

      ar_object = options.delete :for
      if ar_object.is_a? ActiveRecord::Base
        msg = ar_object.errors.full_messages.join(", ")
        errors = ar_object.errors.full_messages
      end

      msg = options.delete(:msg) || msg || "error"
      errors = options.delete(:errors) || errors || [msg]

      status error_code
      {
        meta: {
          code: error_code,
          msg: msg,
          errors: errors
        }
      }.to_json
    end
  end

  helpers CoreHelpers
end
