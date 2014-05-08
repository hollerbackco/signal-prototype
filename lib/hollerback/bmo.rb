module Hollerback
  class BMO
    def self.say(msg)
      if Sinatra::Base.production? 
        uri = URI('http://still-depths-4143.herokuapp.com/hubot/say')
        res = Net::HTTP.post_form(uri, 'room' => 'C024G8VHM', 'message' => msg)
      end
    end
  end
end
