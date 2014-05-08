require 'spec_helper'

describe Message do
  before(:all) do
    conversation = FactoryGirl.create(:conversation)
    conversation.members << FactoryGirl.create(:user)
    @membership = conversation.memberships.first
    @message = Message.create(membership: @membership, video_guid: SecureRandom.uuid)
  end

  let(:membership) { @membership }
  let(:message) { @message }

  it "should update seen_at when seen! is called" do
    message.seen_at.should be_nil
    message.seen!
    message.seen_at.class.should == Time
  end

  it "should find message by guid" do
    guid =  message.guid
    found = Message.find_by_guid(guid)
    found.should_not be_nil
  end

  it "should create a ttyl object" do
    message = membership.messages.new
    message.content["subtitle"] = "ttyl"
    message.save
    message.new_record?.should be_false
  end

  it "should update the membership" do
    message = membership.messages.new
    message.content["subtitle"] = "ttyl"
    message.save
    membership.reload.most_recent_subtitle.should == "ttyl"
  end

  it "messages that are watchable should not include ttyl" do
    messages = membership.messages.watchable
    messages.each do |message|
      message.ttyl?.should_not be_true
    end
  end
end
