module PhoneFake
  def self.phone_number
    rand(10 ** 10).to_s.rjust(10,'0')
  end
end

FactoryGirl.define do
  factory :user do
    username            { Faker::Internet.user_name.gsub(".","_")}
    phone               { PhoneFake.phone_number }
    email               { Faker::Internet.email }

    after(:create) do |user|
      user.devices << Device.create(platform: "ios", token: "devicetoken#{Faker::Name.name}", description: "ios1")
    end
  end
end
