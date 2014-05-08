module Hollerback
  class ContactChecker
    attr_accessor :options

    def defaults
      {
        :include_will => false
      }
    end

    def initialize(options={})
      self.options = defaults.merge options
    end

    def find_by_hashed_phone(numbers)
      contacts = User.where(phone_hashed: numbers.uniq)
      #contacts = remove_will(contacts)
    end

    def find_by_phone(numbers)
      contacts = User.where(phone_normalized: numbers)
      #users = User.all(conditions: [ "phone_normalized IN (:phone_normalized)", {phone_normalized: numbers}]).flatten.uniq
      #contacts = remove_will(contacts)
    end

    def remove_will(contacts)
      #TODO remove this after launch
      user = User.where(email: "williamldennis@gmail.com").first
      contacts = contacts - [user]

      if options[:include_will] and user
        user.name = "Will Dennis - Cofounder of Hollerback"
        contacts << user if user
      end

      contacts
    end
  end
end
