require 'spec_helper'

describe WelcomeUser do
  before(:all) do
    user = FactoryGirl.create(:user)
    will = FactoryGirl.create(:user)
    @welcome_user_service = WelcomeUser.new(user,will)
  end

  let(:welcome_user_service) {@welcome_user_service}

  it "should welcome users" do
    welcome_user_service.run
    welcome_user_service.user.conversations.count.should_not == 0
  end
end
