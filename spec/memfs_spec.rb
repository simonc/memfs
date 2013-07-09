require 'spec_helper'

describe MemFs do
  subject { MemFs }

  describe '.activate' do
    it "calls the given block with MemFs activated" do
      subject.activate do
        expect(::Dir).to be(MemFs::Dir)
      end
    end

    it "resets the original classes once finished" do
      subject.activate {}
      expect(::Dir).to be(MemFs::OriginalDir)
    end

    it "deactivates MemFs even when an exception occurs" do
      begin
        subject.activate { raise 'Some error' }
      rescue
      end
      expect(::Dir).to be(MemFs::OriginalDir)
    end
  end

  describe '.activate!' do
    before(:each) { subject.activate! }
    after(:each)  { subject.deactivate! }

    it "replaces Ruby Dir class with a fake one" do
      expect(::Dir).to be(MemFs::Dir)
    end

    it "replaces Ruby File class with a fake one" do
      expect(::File).to be(MemFs::File)
    end

    it "sets the umask to the same value than the system one" do
      expect(MemFs::File.umask).to eq(MemFs::OriginalFile.umask)
    end
  end

  describe '.deactivate!' do
    before :each do
      subject.activate!
      subject.deactivate!
    end

    it "sets back the Ruby Dir class to the original one" do
      expect(::Dir).to be(MemFs::OriginalDir)
    end

    it "sets back the Ruby File class to the original one" do
      expect(::File).to be(MemFs::OriginalFile)
    end
  end
end
