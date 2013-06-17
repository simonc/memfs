require 'spec_helper'

describe MemFs do
  describe '.activate' do
    it "calls the given block with MemFs activated" do
      MemFs.activate do
        ::Dir.should be(MemFs::Dir)
      end
    end

    it "resets the original classes once finished" do
      MemFs.activate {}
      ::Dir.should be(MemFs::OriginalDir)
    end

    it "deactivates MemFs even when an exception occurs" do
      begin
        MemFs.activate { raise 'Some error' }
      rescue
      end
      ::Dir.should be(MemFs::OriginalDir)
    end
  end

  describe '.activate!' do
    before(:each) { MemFs.activate! }
    after(:each)  { MemFs.deactivate! }

    it "replaces Ruby Dir class with a fake one" do
      ::Dir.should be(MemFs::Dir)
    end

    it "replaces Ruby File class with a fake one" do
      ::File.should be(MemFs::File)
    end
  end

  describe '.deactivate!' do
    before :each do
      MemFs.activate!
      MemFs.deactivate!
    end

    it "sets back the Ruby Dir class to the original one" do
      ::Dir.should be(MemFs::OriginalDir)
    end

    it "sets back the Ruby File class to the original one" do
      ::File.should be(MemFs::OriginalFile)
    end
  end
end
