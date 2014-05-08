require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AppLink do
  before(:all) do
    @link ||= AppLink.where(slug: "first").first_or_create
  end

  let(:app_link) { @link.reload }

  it "should be usable" do
    app_link.usable?.should be_true
  end

  it "should increment the link" do
    app_link.increment!(:downloads_count)
    app_link.downloads_count.should > 0
  end

  it "should not be usable if max downloads has been reached" do
    app_link.downloads_count = 6
    app_link.max_downloads = 3
    app_link.usable?.should be_false
  end

  it "should not be usable if expired" do
    app_link.usable?.should be_true
    app_link.expires_at = Time.now - 1.day
    app_link.usable?.should be_false
  end
end
