require 'spec_helper'

class CoreHelpersTest
  include Sinatra::CoreHelpers

  def initialize(user)
    @user = user
  end

  def current_user
    @user
  end
end

describe 'Core helpers' do
  before do
    @user ||= User.create!(
      username: "helpers",
      phone: "+18886669999"
    )

    @conversation = @user.conversations.create
  end

  after(:all) do
    DatabaseCleaner.clean_with(:truncation)
  end

  let(:subject) { CoreHelpersTest.new(@user) }
  let(:user) { @user }
  let(:conversation) { @conversation }
end
