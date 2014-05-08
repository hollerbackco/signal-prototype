require 'spec_helper'

describe Hollerback::SMS do
  let(:user) do
    User.create(
      email: "tester@test.com",
      username: "tester",
      password: "password",
      name: "Tester",
      phone: "+18587614144"
    )
  end

  it "sends a message" do
    Hollerback::SMS.send_message user.phone, "hello"
    open_last_text_message_for user.phone
    current_text_message.should have_body "hello"
  end
end
