require 'spec_helper'

describe RemindInactive do
  before(:all) do
    @user = FactoryGirl.create(:user)
    @second_user = FactoryGirl.create(:user)
    @conversation = FactoryGirl.create(:conversation)
    @conversation.members << @user
    @conversation.members << @second_user
    @membership = Membership.where(user_id: @user.id).first
    @reminders = RemindInactive::UserReminders.new(@user)
    @reminders.reset

    10.times do
      @membership.messages.create(
        is_sender: false,
        sent_at: (Time.now - 1.week),
        content: {
          guid: "adfas"
        }
      )
      @membership.messages.create(
        is_sender: true,
        sent_at: (Time.now - 1.week),
        content: {
          guid: "adfas"
        }
      )
    end
  end

  let(:user) { @user }
  let(:second_user) { @second_user }
  let(:membership) { @membership }
  let(:reminders) { @reminders }

  describe "remindable?" do
    it "should be true if user is not active and has unseen messages" do
      reminder = RemindInactive.new(user: user)
      user.active?.should be_false
      reminder.remindable_message.present?.should be_true
      reminder.remindable?.should be_true
    end

    it "should be false if user has received no unseen messages" do
      reminder = RemindInactive.new(user: second_user)
      reminder.remindable_message.blank?.should be_true
      reminder.remindable?.should be_false
    end
  end

  describe "remind" do
    it "should send a push and track the reminder" do
      reminder = RemindInactive.new(user: user)
      reminder.remindable?.should be_true
      reminder.remind
      reminder.remindable?.should be_false
    end
  end

  describe "UserReminders" do
    it "create a message should be persisted" do
      message = membership.messages.create({
        content: {guid: "asdf"}
      })
      reminders.create(message)
      reminders.message_ids.include?(message.id).should be_true
    end

    it "create a message should be persisted" do
      message = membership.messages.create({
        content: {guid: "asdf"}
      })
      reminders.create(message)
      reminders.message_ids.include?(message.id).should be_true
    end

    it "a message that is reminded should return true for reminded?" do
      message = membership.messages.create({
        content: {guid: "asdf"}
      })
      reminders.create(message)
      reminders.reminded?(message).should be_true
    end
  end
end
