require 'spec_helper'

describe 'API | register endpoint' do
  before(:all) do
    @user ||= FactoryGirl.create(:user)
  end

  let(:subject) { @user }

  it 'POST session | should respond with success phone number' do
    device_count = subject.devices.count
    post '/session', :phone => subject.phone_normalized

    result = JSON.parse(last_response.body)
    last_response.should be_ok
  end

  it 'DELETE session | deletes the device' do
    user = FactoryGirl.create(:user)
    device_count = user.devices.count

    delete '/session', :access_token => user.devices.first.access_token
    last_response.should be_ok

    user.devices.count.should == device_count - 1
  end
end
