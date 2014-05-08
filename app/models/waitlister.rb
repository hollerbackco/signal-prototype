class Waitlister < ActiveRecord::Base
  attr_accessible :email, :phone

  validates :email, presence: true, uniqueness: {:message => 'thanks, you\'re on the list'}
  validates_format_of :email, with: /.+@.+\..+/i

  def phone=(phone_string)
    self[:phone] = Phoner::Phone.parse(phone_string).to_s
  end
end
