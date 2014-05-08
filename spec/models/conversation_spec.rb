require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Conversation do
  before(:all) do
    @conversation = FactoryGirl.create(:conversation)
    @first_user = FactoryGirl.create(:user)
    @second_user = FactoryGirl.create(:user)

    @conversation.members << @conversation.creator
    @conversation.members << @first_user
    @conversation.members << @second_user
  end

  let(:conversation) { @conversation }
  let(:user) { @conversation.creator }
  let(:second_user) { @second_user }

  let(:phones) do
    @phones = [user, @first_user, @second_user].map {|u| u.phone_normalized}
  end

  let(:wrong_phones) do
    phones + phones
  end

  it "find_by_phones should be able to find the right convo" do
    matches = user.conversations.find_by_phones(phones)
    matches.should_not be_empty
    matches[0].is_a?(Conversation).should be_true
  end

  it "find_by_phones should be able to find the right conversation if phones are not unique" do
    matches = user.conversations.find_by_phones(wrong_phones)
    matches.should_not be_empty
    matches[0].is_a?(Conversation).should be_true
  end

  it "find_by_phones should not match if numbers are incorrect " do
    matches = user.conversations.find_by_phones(wrong_phones + [@first_user.phone])
    matches.should be_empty
  end
end
