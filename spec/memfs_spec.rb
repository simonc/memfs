require 'spec_helper'

describe MemFs do
  subject { MemFs }

  describe '.activate' do
    it 'calls the given block with MemFs activated' do
      subject.activate do
        expect(::Dir).to be(MemFs::Dir)
      end
    end

    it 'resets the original classes once finished' do
      subject.activate {}
      expect(::Dir).to be(MemFs::OriginalDir)
    end

    it 'deactivates MemFs even when an exception occurs' do
      begin
        subject.activate { fail 'Some error' }
      rescue
      end
      expect(::Dir).to be(MemFs::OriginalDir)
    end
  end

  describe '.activate!' do
    before(:each) { subject.activate! }
    after(:each)  { subject.deactivate! }

    it 'replaces Ruby Dir class with a fake one' do
      expect(::Dir).to be(MemFs::Dir)
    end

    it 'replaces Ruby File class with a fake one' do
      expect(::File).to be(MemFs::File)
    end
  end

  describe '.deactivate!' do
    before :each do
      subject.activate!
      subject.deactivate!
    end

    it 'sets back the Ruby Dir class to the original one' do
      expect(::Dir).to be(MemFs::OriginalDir)
    end

    it 'sets back the Ruby File class to the original one' do
      expect(::File).to be(MemFs::OriginalFile)
    end
  end

  describe '.touch' do
    around(:each) { |example| MemFs.activate { example.run } }

    it 'creates the specified file' do
      fs.mkdir('/path')
      fs.mkdir('/path/to')
      fs.mkdir('/path/to/some')
      subject.touch('/path/to/some/file.rb')
      expect(File.exist?('/path/to/some/file.rb')).to be true
    end

    context 'when the parent folder do not exist' do
      it 'creates them all' do
        subject.touch('/path/to/some/file.rb')
        expect(File.exist?('/path/to/some/file.rb')).to be true
      end
    end

    context 'when several files are specified' do
      it 'creates every file' do
        subject.touch('/some/path', '/other/path')
        expect(File.exist?('/some/path')).to be true
        expect(File.exist?('/other/path')).to be true
      end
    end
  end
end
