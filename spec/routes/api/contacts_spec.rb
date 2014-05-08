require 'spec_helper'

describe 'API | contacts endpoint' do
  before(:all) do
    @user ||= FactoryGirl.create(:user)

    3.times do
      @user.conversations.create
    end

    @user.conversations.each do |conversation|
      membership = Membership.where(user_id: @user.id, conversation_id: conversation.id).first
      10.times do
        publisher = ContentPublisher.new(membership)
        video = conversation.videos.create(user: @user, :filename => "hello.mp4", in_progress: false)
        publisher.publish(video, notify: false, analytics: false)
      end
    end

    @second_user ||= FactoryGirl.create(:user)
    @conversation = @user.conversations.last
    @access_token = @user.devices.first.access_token
    @second_token = @second_user.devices.first.access_token
  end

  let(:subject) { @user }
  let(:secondary_subject) { @second_user }
  let(:conversation) { @conversation }
  let(:access_token) { @access_token }
  let(:second_token) { @second_token }

  it 'GET contacts/check | return users from an array or phonenumbers' do
    get '/contacts/check', :numbers => [[secondary_subject.phone_normalized]]

    result = JSON.parse(last_response.body)

    secondary_subject.username.should == result['data'][0]["username"]

    last_response.should be_ok
  end

  it 'GET contacts/check | return contacts' do
    get '/contacts/check', :c => [{"n" => secondary_subject.username, "p" => secondary_subject.phone_hashed}]

    result = JSON.parse(last_response.body)

    secondary_subject.username.should == result['data'][0]["username"]

    last_response.should be_ok
  end

  it 'GET contacts/check | return contacts with access_token' do
    get '/contacts/check', :access_token => access_token, :c => [{"n" => secondary_subject.username, "p" => secondary_subject.phone_hashed}]

    result = JSON.parse(last_response.body)

    secondary_subject.username.should == result['data'][0]["username"]

    last_response.should be_ok
  end
end
