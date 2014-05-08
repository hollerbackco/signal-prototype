require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Invite do
  before(:all) do
    @user = FactoryGirl.create(:user)
    @conversation = FactoryGirl.create(:conversation)
    @invite = @conversation.invites.create(
      phone: @user.phone
    )
  end

  let(:user) { @user }

  it "a new invite should start off as not accepted" do
    @invite.accepted?.should be_false
  end

  it "requires a phone" do
    invite = Invite.create
    invite.errors.any?.should be_true
  end

  it "set waitlisted" do
    invite = Invite.create(phone: "333")
    invite.waitlisted!

    invite.waitlisted.should be_true
  end

  it "should omit waitlisted from standard queries" do
    invite = Invite.create(phone: "3334445555")
    invite.waitlisted!
    invites = Invite.where(phone: "3334445555")
    invites.count.should == 0
  end

  it "find all by phone" do
    phone = "8587614144"
    phone_normalized = Phoner::Phone.parse(phone).to_s
    invite = Invite.create(phone: phone_normalized)
    invite = Invite.create(phone: phone_normalized)
    invites = Invite.find_all_by_phone(phone)

    invites.count.should == 2
  end

  it "when accepted and join a user to a group" do
    @conversation.members.should_not include(@user)

    @invite.accept!(@user)

    @conversation.members.reload.should include(@user)
    @invite.accepted?.should be_true
  end
end
