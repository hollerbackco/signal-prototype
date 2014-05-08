require 'spec_helper'

describe 'API | register endpoint' do
  before(:all) do
    @user ||= FactoryGirl.create(:user)
  end

  let(:subject) { @user }

  it 'POST verify | should return access_token' do
    post '/verify',
      phone: subject.phone_normalized,
      code: subject.verification_code,
      platform: "android",
      device_token: "hello"

    result = JSON.parse(last_response.body)
    last_response.should be_ok
    result['access_token'].should_not be_nil
    result['user']['access_token'].should_not be_nil
  end

  it 'POST verify | should fail: requires params' do
    post '/verify'

    result = JSON.parse(last_response.body)
    last_response.should_not be_ok
    result['meta']['msg'].should_not be_blank
    result['meta']['errors'].is_a?(Array).should be_true
  end

  it 'POST register | should fail: requires params' do
    post '/register'

    result = JSON.parse(last_response.body)
    last_response.should_not be_ok
    result['meta']['msg'].should_not be_blank
    result['meta']['errors'].is_a?(Array).should be_true
  end

  it 'POST register | creates a user' do
    post '/register',
      username: "myname",
      phone: "8587614144",
      email: "anothertest@test.com",
      password: "hello"

    result = JSON.parse(last_response.body)
    last_response.should be_ok
  end

  it 'POST register | should throw error if email is already used' do
    post '/register',
      username: "myname",
      phone: "8587614144",
      email: "anothertest@test.com",
      password: "hellohello"

    result = JSON.parse(last_response.body)
    last_response.should_not be_ok
  end

  it 'POST register | should throw error if username is already used' do
    post '/register',
      email: "test@tester.com",
      password: "hello",
      phone: "8587611111",
      username: subject.username

    result = JSON.parse(last_response.body)
    last_response.should_not be_ok
  end

  it 'POST register | should throw error if phone is already used' do
    post '/register',
      email: "test@tester10.com",
      username: "testuser",
      phone: subject.phone

    result = JSON.parse(last_response.body)
    last_response.should_not be_ok
  end
end
