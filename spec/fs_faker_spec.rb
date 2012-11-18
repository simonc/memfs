require 'spec_helper'

describe FsFaker do
  describe '.activate' do
    it "calls the given block with FsFaker activated" do
      FsFaker.activate do
        ::Dir.should be(FsFaker::Dir)
      end
    end

    it "resets the original classes once finished" do
      FsFaker.activate {}
      ::Dir.should be(FsFaker::OriginalDir)
    end

    it "deactivates FsFaker even when an exception occurs" do
      begin
        FsFaker.activate { raise 'Some error' }
      rescue
      end
      ::Dir.should be(FsFaker::OriginalDir)
    end
  end

  describe '.activate!' do
    before(:each) { FsFaker.activate! }
    after(:each)  { FsFaker.deactivate! }

    it "replaces Ruby Dir class with a fake one" do
      ::Dir.should be(FsFaker::Dir)
    end

    it "replaces Ruby File class with a fake one" do
      ::File.should be(FsFaker::File)
    end
  end

  describe '.deactivate!' do
    before :each do
      FsFaker.activate!
      FsFaker.deactivate!
    end

    it "sets back the Ruby Dir class to the original one" do
      ::Dir.should be(FsFaker::OriginalDir)
    end

    it "sets back the Ruby File class to the original one" do
      ::File.should be(FsFaker::OriginalFile)
    end
  end
end
