require 'spec_helper'

describe ContentPublisher do
  before(:all) do
    conversation = FactoryGirl.create(:conversation)
    second_user = FactoryGirl.create(:user)
    conversation.members << second_user
    conversation.invites << Invite.create(:phone => "+18888888888")
    conversation.videos.create(filename: "hello.mp4")
    @membership = Membership.where(:user_id => second_user.id, :conversation_id => conversation.id).first
  end

  subject {ContentPublisher.new(@membership)}
  let(:membership) {@membership}
  let(:conversation) {@membership.conversation}

  it "should publish and return messages" do
    video = FactoryGirl.create(:video)
    subject.publish(video)
    subject.messages.should_not be_empty
  end

  it "should not publish a message to muted users" do
    user = FactoryGirl.create(:user)
    conversation.members << user
    user.mute! membership.user

    video = FactoryGirl.create(:video)
    subject.publish(video)
    subject.messages.count.should == conversation.members.count - 1
  end
end
