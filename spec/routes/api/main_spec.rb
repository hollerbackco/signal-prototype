require 'spec_helper'

describe 'API | main endpoints' do
  before(:all) do
    @user ||= FactoryGirl.create(:user)
    @access_token = @user.devices.first.access_token
  end

  let(:subject) { @user }
  let(:access_token) { @access_token }

  it 'shows an index' do
    get '/'
    last_response.should be_ok
  end

  it 'GET me | error message when not authenticated' do
    get '/me'
    last_response.should_not be_ok
  end

  it 'POST me | updates the user' do
    post '/me', :access_token => access_token, :username => "hello"
    last_response.should be_ok

    result = JSON.parse(last_response.body)

    subject.reload.username.should == result['data']['username']
  end
end
