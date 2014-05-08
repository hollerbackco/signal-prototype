require 'twilio-ruby'
require 'phone'

module Hollerback
  class SMS
    PHONES = ["+14152758229","+14155285018","+14152300935"]

    class << self
      def configure(sid, token, phone)
        @client = self.client(sid, token)
      end

      def send_message(recipient, msg, media_url=nil)
        data = {
          from: self.phone,
          to: recipient,
          body: msg
        }

        #TODO: turn this on once twilio supports it
        #if media_url
          #data = data.merge(media_url: media_url)
        #end

        @client.account.messages.create(data)
      rescue Twilio::REST::RequestError => e
        p e
      end

      def client(sid,token)
        Twilio::REST::Client.new sid, token
      end

      #TODO: shouldnt' be random. should cycle through them.
      def phone
        PHONES.sample
      end
    end
  end
end
