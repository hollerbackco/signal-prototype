module Signal
  class MQTT

    def self.client_options=(options)
        @client = ::MQTT::Client.connect(options)
    end

    def self.client
      @client
    end

    def self.encrypt_key=(key)
      @key = key
    end

    def self.key
      @key ||= "8926AEC00DA47334F7A4F0689AA3E6B4"
    end

    def self.configure(&block)
      yield self
    end

    def self.publish(channel, data, retain=false, qos=0)
      data = encrypt(data.to_json)
      client.publish(channel, data, retain, qos)
    end

    def self.encrypt(data)
      xtea = Xtea.new(key, 64)
      xtea.encrypt(data)
    end
  end
end
