require 'spec_helper'

module MemFs
  module Fake
    describe Symlink do
      describe '#content' do
        it "returns the target's content" do
          MemFs::File.open('/test-file', 'w') { |f| f.puts 'test' }
          s = described_class.new('/test-link', '/test-file')
          expect(s.content).to be(s.dereferenced.content)
        end
      end

      describe '#dereferenced' do
        it "returns the target if it's not a symlink" do
          _fs.touch '/test-file'
          target = _fs.find!('/test-file')

          s = described_class.new('/test-link', '/test-file')

          expect(s.dereferenced).to eq(target)
        end

        it 'returns the last target of the chain' do
          _fs.touch '/test-file'
          target = _fs.find!('/test-file')

          _fs.symlink '/test-file', '/test-link'
          s = described_class.new('/test-link2', '/test-link')

          expect(s.dereferenced).to eq(target)
        end
      end

      describe '#dereferenced_name' do
        context "when the symlink's target exists" do
          it 'returns its target name' do
            _fs.touch('/test-file')
            symlink = described_class.new('/test-link', '/test-file')
            expect(symlink.dereferenced_name).to eq('test-file')
          end
        end

        context "when the symlink's target does not exist" do
          it 'returns its target name' do
            symlink = described_class.new('/test-link', '/no-file')
            expect(symlink.dereferenced_name).to eq('no-file')
          end
        end
      end

      describe '#dereferenced_path' do
        context "when the symlink's target exists" do
          it 'returns its target path' do
            _fs.touch('/test-file')
            symlink = described_class.new('/test-link', '/test-file')
            expect(symlink.dereferenced_path).to eq('/test-file')
          end
        end

        context "when the symlink's target does not exist" do
          it 'raises an exception' do
            symlink = described_class.new('/test-link', '/no-file')
            expect {
              symlink.dereferenced_path
            }.to raise_error Errno::ENOENT
          end
        end
      end

      describe '#find' do
        let(:file) { _fs.find!('/test-dir/test-file') }

        before :each do
          _fs.mkdir '/test-dir'
          _fs.touch '/test-dir/test-file'
        end

        context "when the symlink's target exists" do
          subject { described_class.new('/test-dir-link', '/test-dir') }

          it 'forwards the search to it' do
            entry = subject.find('test-file')
            expect(entry).to eq(file)
          end
        end

        context "when the symlink's target does not exist" do
          subject { described_class.new('/test-no-link', '/no-dir') }

          it 'returns nil' do
            entry = subject.find('test-file')
            expect(entry).to be_nil
          end
        end
      end

      describe '#target' do
        it 'returns the target of the symlink' do
          s = described_class.new('/test-link', '/test-file')
          expect(s.target).to eq('/test-file')
        end
      end

      describe '#type' do
        it "returns 'link'" do
          s = described_class.new('/test-link', '/test-file')
          expect(s.type).to eq('link')
        end
      end
    end
  end
end
