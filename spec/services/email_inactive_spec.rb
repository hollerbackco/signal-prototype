require 'spec_helper'

describe EmailInactive do
  before(:all) do
    @user = FactoryGirl.create(:user)
    @second_user = FactoryGirl.create(:user)
    @conversation = FactoryGirl.create(:conversation)
    @conversation.members << @user
    @conversation.members << @second_user
    @membership = Membership.where(user_id: @user.id).first

    10.times do
      @membership.messages.create(
        is_sender: false,
        sent_at: (Time.now - 2.week),
        content: {
          guid: "adfas"
        }
      )
      @membership.messages.create(
        is_sender: true,
        sent_at: (Time.now - 2.week),
        content: {
          guid: "adfas"
        }
      )
    end
  end

  let(:user) { @user }
  let(:second_user) { @second_user }
  let(:membership) { @membership }

  describe "email" do
    it "should send an email reminder" do
      emailer = EmailInactive.new(user: user)
      emailer.remindable?.should be_true
      emailer.remind
    end
  end
end
