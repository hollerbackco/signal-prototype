require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Membership do
  before(:all) do
    conversation = FactoryGirl.create(:conversation)
    conversation.members << conversation.creator
    conversation.members << FactoryGirl.create(:user)
    @membership = Membership.first
    publisher = ContentPublisher.new(@membership)
    video = conversation.videos.create(user: @user, :filename => "hello.mp4", in_progress: false)
    publisher.publish(video, notify: false, analytics: false)
  end

  let(:membership) { @membership }

  it "json should have an updated_at equal to last_message_at" do
    json = membership.as_json
    membership.messages.should_not be_empty
    json.key?(:updated_at).should be_true
    json[:updated_at].should == membership.last_message_at
  end

  it "should respond to seen_without_response" do
    membership.seen_without_response
    p membership.messages.last.subtitle
    membership.messages.last.subtitle.present?.should be_true
  end
end
