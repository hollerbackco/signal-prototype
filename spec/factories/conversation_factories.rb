FactoryGirl.define do
  factory :conversation do
    creator { FactoryGirl.build(:user) }
  end
end
