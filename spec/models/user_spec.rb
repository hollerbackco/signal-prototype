require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do
  before(:all) do
    @user ||= FactoryGirl.create(:user)
  end

  after(:all) do
    DatabaseCleaner.clean!
  end

  let(:user) { @user }

  it "should have a device" do
    user.devices.count.should == 1
  end

  it "should respond to friends" do
    user.friends.should_not be_nil
  end

  it "should grab general device if it exists and nil values" do
    new_device = user.devices.create(platform: "general")
    get_device = user.device_for(nil,nil)
    new_device.should == get_device
  end

  it "device should have an access_token" do
    user.devices.first.access_token.should_not be_nil
  end

  it "should generate a verification thats 4 characters in length" do
    user.verification_code.should_not be_nil
    user.verification_code.to_s.length.should == 4
  end

  it "should not be verified before verifying" do
    user.verified?.should be_false
  end

  it "should return a hashed phone" do
    user.phone_hashed.should_not be_nil
  end

  it "should return standard username if no alias exists" do
    user.also_known_as(for: user).should == user.username
  end

  it "should return an alias for user" do
    @contact = Contact.create(user_id: @user.id, phone_hashed: @user.phone_hashed, name: "testname")
    user.also_known_as(for: user).should == "testname"
  end

  it "should respond to description" do
    user.device_names.should == "ios1"
  end

  describe "muting of users" do
    it "should have an empty list at first" do
      user.muted_users.is_a?(Array).should be_true
    end

    it "should allow muting/unmuting" do
      second_user = FactoryGirl.create(:user)
      user.muted?(second_user).should be_false
      user.mute! second_user
      user.muted?(second_user).should be_true
      user.unmute! second_user
      user.muted?(second_user).should be_false
    end
  end

  describe "create" do
    it "should downcase uppercased username" do
      username = "TESTER"
      user = User.create({
        email: "testemail@email.com",
        username: username,
        phone: "15551114444",
        password: "password"
      })

      user.valid?.should be_true
      user.username.should == username.downcase
    end

    it "should downcase uppercased emails" do
      email = "TESTEMAILUPPERCASE@email.com"
      user = User.create({
        email: email,
        username: "username",
        phone: "15551113333",
        password: "password"
      })

      user.valid?.should be_true
      user.email.should == email.downcase
    end

    describe "errors" do
      it "throw only one error if phone is missing" do
        user = User.create({
          email: "test@test.com",
          username: "test",
          password: "password"
        })

        user.valid?.should_not be_true
        user.errors.full_messages.count.should == 1
      end

      it "should not allow duplicate phone numbers" do
        user = User.create({
          email: "test@test.com",
          username: "test",
          phone: "15551113333",
          password: "password"
        })

        user.valid?.should_not be_true
        user.errors.full_messages.count.should == 1
      end
    end
  end
end
