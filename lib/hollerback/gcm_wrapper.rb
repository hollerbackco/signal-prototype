module Hollerback
  class GcmWrapper

    module TYPE
      SYNC = "sync"
      NOTIFICATION = "notification"
    end

    def self.init
      @@GCMS = GCM.new ENV["GCM_KEY"]
      HollerbackApp::BaseApp::logger.info "initializing gcm"
    end

    def self.send_notification(registration_ids, type, payload = {}, options = {})
      options = {data: {type: type, payload: payload}}.merge(options)
      @@GCMS.send_notification(registration_ids, options)
    end

  end
end
