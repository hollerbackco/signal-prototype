require 'spec_helper'

describe Video do
  it "should allow guid to be set" do
    guid = SecureRandom.uuid
    video = Video.new
    video.guid = guid
    video.save.should be_true
    video.reload.guid.should == guid
  end

  it "should allow video to be destroyed" do
    guid = SecureRandom.uuid
    video = Video.new
    video.guid = guid
    video.save.should be_true

    video.destroy.should be_true
  end
end
