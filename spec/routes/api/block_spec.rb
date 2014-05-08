require 'spec_helper'

describe 'API | block endpoint' do
  before(:all) do
    @user ||= FactoryGirl.create(:user)
    @second_user ||= FactoryGirl.create(:user)
    @access_token = @user.devices.first.access_token
  end

  let(:subject) { @user }
  let(:secondary_subject) { @second_user }
  let(:access_token) { @access_token }

  it 'POST me/users/:id/mute | mute user' do
    post "/me/users/#{secondary_subject.id}/mute", :access_token => access_token
    last_response.should be_ok

    subject.reload.muted?(secondary_subject).should be_true
  end

  it 'POST me/users/:id/unmute | unmute user' do
    post "/me/users/#{secondary_subject.id}/unmute", :access_token => access_token
    last_response.should be_ok

    subject.reload.muted?(secondary_subject).should be_false
  end
end
