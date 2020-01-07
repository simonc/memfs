require 'spec_helper'

RSpec.describe MemFs do
  describe '.activate' do
    it 'calls the given block with MemFs activated' do
      described_class.activate do
        expect(::Dir).to be(described_class::Dir)
      end
    end

    it 'resets the original classes once finished' do
      described_class.activate {}
      expect(::Dir).to be(described_class::OriginalDir)
    end

    it 'deactivates MemFs even when an exception occurs' do
      begin
        described_class.activate { fail 'Some error' }
      rescue RuntimeError
      end
      expect(::Dir).to be(described_class::OriginalDir)
    end
  end

  describe '.activate!' do
    before(:each) { described_class.activate! }
    after(:each)  { described_class.deactivate! }

    it 'replaces Ruby Dir class with a fake one' do
      expect(::Dir).to be(described_class::Dir)
    end

    it 'replaces Ruby File class with a fake one' do
      expect(::File).to be(described_class::File)
    end
  end

  describe '.deactivate!' do
    before :each do
      described_class.activate!
      described_class.deactivate!
    end

    it 'sets back the Ruby Dir class to the original one' do
      expect(::Dir).to be(described_class::OriginalDir)
    end

    it 'sets back the Ruby File class to the original one' do
      expect(::File).to be(described_class::OriginalFile)
    end
  end

  describe '.halt' do
    before(:each) { described_class.activate! }
    after(:each)  { described_class.deactivate! }

    it 'switches back to the original Ruby Dir & File classes' do
      described_class.halt do
        expect(::Dir).to be(described_class::OriginalDir)
        expect(::File).to be(described_class::OriginalFile)
      end
    end

    it 'switches back to the faked Dir & File classes' do
      described_class.halt
      expect(::Dir).to be(described_class::Dir)
      expect(::File).to be(described_class::File)
    end

    it 'switches back to the faked Dir & File classes no matter what' do
      begin
        described_class.halt { fail 'Fatal Error' }
      rescue
        expect(::Dir).to be(described_class::Dir)
        expect(::File).to be(described_class::File)
      end
    end

    it 'maintains the state of the faked fs' do
      _fs.touch('file.rb')

      described_class.halt do
        expect(File.exist?('file.rb')).to be false
      end

      expect(File.exist?('file.rb')).to be true
    end
  end

  describe '.touch' do
    around(:each) { |example| described_class.activate { example.run } }

    it 'creates the specified file' do
      _fs.mkdir('/path')
      _fs.mkdir('/path/to')
      _fs.mkdir('/path/to/some')
      described_class.touch('/path/to/some/file.rb')
      expect(File.exist?('/path/to/some/file.rb')).to be true
    end

    context 'when the parent folder do not exist' do
      it 'creates them all' do
        described_class.touch('/path/to/some/file.rb')
        expect(File.exist?('/path/to/some/file.rb')).to be true
      end
    end

    context 'when several files are specified' do
      it 'creates every file' do
        described_class.touch('/some/path', '/other/path')
        expect(File.exist?('/some/path')).to be true
        expect(File.exist?('/other/path')).to be true
      end
    end
  end
end
