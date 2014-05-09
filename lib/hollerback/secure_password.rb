module Signal
  module SecurePassword
    require 'bcrypt'

    def authenticate(unencrypted_password)
      if BCrypt::Password.new(password_digest) == unencrypted_password
        self
      else
        false
      end
    end

    def password=(unencrypted_password)
      @password = unencrypted_password
      unless unencrypted_password.blank?
        self.password_digest = BCrypt::Password.create(unencrypted_password)
      end
    end
  end
end
