require 'spec_helper'

describe Waitlister do
  it "should create a user with a valid email" do
    Waitlister.create!(
      :email    => "user@example.com"
    )
  end

  it "should raise an error with an invalid address" do
    lambda { Waitlister.create!(email: "user") }.should raise_error(ActiveRecord::RecordInvalid)
  end

  it "should normalize phone" do
    waitlister = Waitlister.create(email: "test@test.com")
    waitlister.phone = "4446667777"
    waitlister.phone.should == "+14446667777"
  end

  it "should not create two wailisters with the same email address" do
    email = "user@example.com"

    Waitlister.create(email: email)

    lambda do
      Waitlister.create!(email: email)
    end.should raise_error(ActiveRecord::RecordInvalid)
  end
end
