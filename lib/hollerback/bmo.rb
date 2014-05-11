module Signal
  class BMO
    def self.say(msg)
      if Sinatra::Base.production?
        uri = URI('http://still-depths-4143.herokuapp.com/hubot/say')
        res = Net::HTTP.post_form(uri, 'room' => '#signal', 'message' => msg)
      end
    end
  end
end
