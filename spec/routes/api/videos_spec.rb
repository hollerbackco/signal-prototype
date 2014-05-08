require 'spec_helper'

describe 'API | videos endpoint' do
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
    @access_token = @user.devices.first.access_token
  end

  before(:each) do
    VideoStitchRequest.jobs.clear
  end

  let(:subject) { @user }
  let(:access_token) { @access_token }

  describe "POST me/conversations/:id/videos/parts" do
    it 'sends a video' do
      parts = [
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.0.mp4",
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.1.mp4",
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.2.mp4",
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.3.mp4",
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.4.mp4",
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.5.mp4",
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.6.mp4"
      ]

      post "/me/conversations/#{subject.memberships.first.id}/videos/parts",
        access_token: access_token,
        parts: parts

      last_response.should be_ok
      VideoStitchRequest.jobs.size.should == 1
    end

    it 'should save the part urls in the video object' do
      parts = [
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.0.mp4",
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.1.mp4",
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.2.mp4",
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.3.mp4",
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.4.mp4",
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.5.mp4",
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.6.mp4"
      ]

      post "/me/conversations/#{subject.memberships.first.id}/videos/parts",
        access_token: access_token,
        parts: parts

      last_response.should be_ok

      video = Video.order("created_at DESC").first
      p video.stitch_request
      saved_parts = MultiJson.decode(video.stitch_request["parts"])
      saved_parts.count.should == parts.count
    end

    it 'should accept a guid' do
      parts = [
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.0.mp4",
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.1.mp4",
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.2.mp4"
      ]
      guid = SecureRandom.uuid

      post "/me/conversations/#{subject.memberships.first.id}/videos/parts",
        access_token: access_token,
        parts: parts,
        guid: guid

      last_response.should be_ok

      Video.find_by_guid(guid).present?.should be_true
    end

    it 'sends a video with a subtitle' do
      parts = [
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.0.mp4",
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.1.mp4",
        "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.2.mp4"
      ]

      post "/me/conversations/#{subject.memberships.first.id}/videos/parts",
        access_token: access_token,
        parts: parts,
        subtitle: "hello whats up"

      last_response.should be_ok
      result = JSON.parse(last_response.body)

      VideoStitchRequest.jobs.size.should == 1
      result["data"]["subtitle"].should == "hello whats up"
    end

    it 'requires parts param' do
      post "/me/conversations/#{subject.memberships.first.id}/videos/parts", access_token: access_token

      result = JSON.parse(last_response.body)
      last_response.should_not be_ok
      result['meta']['code'].should == 400
      result['meta']['msg'].should == "missing parts param"
      VideoStitchRequest.jobs.size.should == 0
    end
  end

  it 'POST me/conversations/:id/videos | sends a video' do
    c = subject.memberships.reload.first

    post "/me/conversations/#{c.id}/videos", access_token: access_token, filename: 'video1.mp4'

    last_response.should be_ok
    c.reload.messages.should_not be_empty
  end

  it 'POST me/conversations/:id/videos | requires filename param' do
    c = subject.memberships.first

    post "/me/conversations/#{c.id}/videos", access_token: access_token

    result = JSON.parse(last_response.body)
    last_response.should_not be_ok
    result['meta']['code'].should == 400
    result['meta']['msg'].should == "missing filename param"
  end

  describe "GET me/conversations/:id/videos" do
    it "should get all videos" do
      c = subject.memberships.last
      get "/me/conversations/#{c.id}/videos", :access_token => access_token

      messages_count = c.messages.count

      result = JSON.parse(last_response.body)
      last_response.should be_ok

      result["data"].count.should == messages_count
    end

    it "should paginate" do
      c = subject.memberships.last
      get "/me/conversations/#{c.id}/videos", :access_token => access_token, :page => 1, :perPage => 5

      result = JSON.parse(last_response.body)
      last_response.should be_ok

      result["data"].count.should == 5
      result["meta"]["last_page"].should be_false
    end
  end

  it 'POST me/videos/:id/read | user reads a video' do
    c = subject.memberships.first
    message = c.messages.first
    message.seen_at = nil
    message.save
    message.unseen?.should be_true

    post "/me/videos/#{message.guid}/read", access_token: access_token
    last_response.should be_ok
    message.reload.unseen?.should be_false
  end
end
