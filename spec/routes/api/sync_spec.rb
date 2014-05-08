require 'spec_helper'

describe 'API | Sync endpoint' do
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

  it 'GET me/sync | gets a list of syncable objects' do
    get '/me/sync', :access_token => access_token
    last_response.should be_ok

    result = JSON.parse(last_response.body)
    count = subject.reload.memberships.count + subject.reload.messages.unseen.limit(100).count
    count.should == result['data'].count
  end

  it 'GET me/sync | only get latest sync objects' do
    time = Time.parse(Time.now.to_s)

    membership = subject.memberships.first
    publisher = ContentPublisher.new(membership)
    video = conversation.videos.create(user: subject, :filename => "hello.mp4", in_progress: false)
    publisher.publish(video, notify: false, analytics: false)
    count = subject.reload.memberships.updated_since(time).count + subject.reload.messages.updated_since(time).count

    get '/me/sync', :access_token => access_token, :updated_at => time
    last_response.should be_ok

    result = JSON.parse(last_response.body)

    result['data'].count.should == count
  end
end
