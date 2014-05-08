require 'spec_helper'

describe 'API | conversations endpoint' do
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

  before(:each) do
    VideoStitchRequest.jobs.clear
  end

  let(:subject) { @user }
  let(:secondary_subject) { @second_user }
  let(:conversation) { @conversation }
  let(:access_token) { @access_token }
  let(:second_token) { @second_token }

  it 'GET me/conversations | gets users conversations' do
    get '/me/conversations', :access_token => access_token

    result = JSON.parse(last_response.body)
    conversations = result['data']['conversations']

    last_response.should be_ok
    conversations.should be_a_kind_of(Array)
  end

  it 'POST me/conversations | create a conversation' do
    count = subject.memberships.count
    post '/me/conversations', :access_token => access_token, "invites[]" => [secondary_subject.phone_normalized,"+18888888888"]

    result = JSON.parse(last_response.body)

    last_response.should be_ok
    subject.memberships.reload.count.should == count + 1
    subject.memberships.find(result["data"]["id"]).invites.count.should == 1
  end

  it 'POST me/conversations | create a conversation with a title' do
    name = "this should be a title"
    count = subject.memberships.count
    post '/me/conversations',
      :access_token => access_token,
      "invites[]" => [secondary_subject.phone_normalized,"+18887777777"],
      :name => name

    result = JSON.parse(last_response.body)

    last_response.should be_ok
    subject.memberships.reload.find_by_name(name).should_not be_nil
  end

  # feb 5, 2014 (Jeffrey Noh) we currently support multiple conversations with the
  # same recipients.

  #it 'POST me/conversations | should not create another conversation' do
    #count = subject.conversations.reload.count

    #post '/me/conversations',
      #:access_token => access_token,
      #"invites[]" => [secondary_subject.phone_normalized,"+18887777777"]

    #last_response.should be_ok
    #result = JSON.parse(last_response.body)
    #subject.conversations.reload.count.should == count
  #end

  #it 'POST me/conversations | return error if no invites sent' do
    #count = subject.memberships.count
    #post '/me/conversations', :access_token => access_token

    #result = JSON.parse(last_response.body)

    #last_response.should_not be_ok
    #result['meta']['code'].should == 400
    #result['meta']['msg'].should == "missing invites param"
    #subject.memberships.reload.count.should == count
  #end

  it 'POST me/conversations/:id/watch_all | clear all video notifications' do
    c = secondary_subject.memberships.reload.first
    post "/me/conversations/#{c.id}/watch_all", access_token: second_token

    last_response.should be_ok
  end

  it 'GET me/conversations/:id | get a specific conversation' do
    c = subject.memberships.first
    get "/me/conversations/#{c.id}", :access_token => access_token

    result = JSON.parse(last_response.body)
    last_response.should be_ok
    result['data']['name'].should == subject.memberships.find(c.id).name
  end

  it 'POST me/conversations/:id/leave | leave a group' do
    c = subject.memberships.first
    post "/me/conversations/#{c.id}/leave", access_token: access_token

    subject.memberships.reload.find(c.id).is_deleted.should be_true
  end
end
