require 'spec_helper'

describe 'API | friends endpoint' do
  before(:all) do
    @user ||= FactoryGirl.create(:user)

    3.times do
      @user.conversations.create
    end

    @second_user ||= FactoryGirl.create(:user)
  end

  let(:subject) { @user }
  let(:friend) { @second_user }

  it "should send a list of friends" do
    get '/me/friends', :access_token => @user.devices.first.access_token

    result = JSON.parse(last_response.body)

    last_response.should be_ok
  end

  it "should add a friend by username" do
    post '/me/friends/add', :access_token => subject.devices.first.access_token,
      :username => friend.username

    result = JSON.parse(last_response.body)

    @user.friends.should_not be_empty
    last_response.should be_ok
  end
end
