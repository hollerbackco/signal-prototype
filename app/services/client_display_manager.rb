module SignalApp
  #this class will hold rules related to client side display
  class ClientDisplayManager

    @@rules = {}

    def self.get_rules_by_name(name)
      @@rules[name]
    end

    def self.read_rules
      begin
        @@rules = JSON.parse(File.read('client_views/rules.json'))
      rescue Exception => e
          p e
      end
    end

    #class body method
    self.read_rules

  end
end