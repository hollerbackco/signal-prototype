module Hollerback
  module Random
    extend self

    FRIENDLY_CHARS = [('a'..'z'),('A'..'Z'),("0".."9")].map{|i| i.to_a}.flatten

    def friendly_token(length=15)
      SecureRandom.base64(length).tr('+/=', '0').strip.delete("\n")
    end
  end
end
