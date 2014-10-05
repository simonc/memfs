require 'spec_helper'

describe MemFs do
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
      rescue
      end
      expect(::Dir).to be(described_class::OriginalDir)
    end
  end

  describe '.activate!' do
    it 'replaces Ruby Dir class with a fake one' do
      subject.activate!
      expect(::Dir).to be(described_class::Dir)
      subject.deactivate!
    end

    it 'replaces Ruby File class with a fake one' do
      subject.activate!
      expect(::File).to be(described_class::File)
      subject.deactivate!
    end

    context 'when Pathname is defined' do
      it 'replaces Ruby Pathname class with a fake one' do
        class ::Pathname; end
        subject.activate!
        expect(::Pathname).to be(described_class::Pathname)
        subject.deactivate!
        Object.send(:remove_const, :Pathname)
      end
    end

    context 'when Pathname is not defined' do
      it 'does not replace Ruby Pathname class with a fake one' do
        subject.activate!
        expect { Object.const_get(:Pathname) }.to raise_error(NameError)
        subject.deactivate!
      end
    end
  end

  describe '.deactivate!' do
    it 'sets back the Ruby Dir class to the original one' do
      subject.activate!
      subject.deactivate!
      expect(::Dir).to be(described_class::OriginalDir)
    end

    it 'sets back the Ruby File class to the original one' do
      subject.activate!
      subject.deactivate!
      expect(::File).to be(described_class::OriginalFile)
    end

    context 'when Pathname is defined' do
      it 'sets back the Ruby Pathname class to the original one' do
        class ::Pathname; end
        subject.activate!
        subject.deactivate!
        expect(::Pathname).to be(described_class::OriginalPathname)
        Object.send(:remove_const, :Pathname)
      end
    end

    context 'when Pathname is not defined' do
      it 'does not set the Pathname constant' do
        subject.activate!
        subject.deactivate!
        expect { Object.const_get(:Pathname) }.to raise_error(NameError)
      end
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
