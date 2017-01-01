require 'spec_helper'

module MemFs
  module Fake
    ::RSpec.describe Directory do
      subject(:directory) { described_class.new('test') }

      describe '.new' do
        it 'sets . in the entries list' do
          expect(directory.entries).to include('.' => directory)
        end

        it 'sets .. in the entries list' do
          expect(directory.entries).to have_key('..')
        end
      end

      describe '#add_entry' do
        let(:entry) { described_class.new('new_entry') }

        it 'adds the entry to the entries list' do
          directory.add_entry entry
          expect(directory.entries).to include('new_entry' => entry)
        end

        it 'sets the parent of the added entry' do
          directory.add_entry entry
          expect(entry.parent).to be(directory)
        end
      end

      describe 'empty?' do
        it 'returns true if the directory is empty' do
          expect(directory).to be_empty
        end

        it 'returns false if the directory is not empty' do
          directory.add_entry described_class.new('test')
          expect(directory).not_to be_empty
        end
      end

      describe '#entry_names' do
        it 'returns the list of the names of the entries in the directory' do
          3.times do |n|
            directory.add_entry described_class.new("dir#{n}")
          end

          expect(directory.entry_names).to eq(%w[. .. dir0 dir1 dir2])
        end
      end

      describe '#find' do
        let(:sub_directory) { described_class.new('sub_dir') }
        let(:file) { File.new('file') }

        before :each do
          sub_directory.add_entry file
          directory.add_entry sub_directory
        end

        it 'returns the named entry if it is one of the entries' do
          expect(directory.find('sub_dir')).to be(sub_directory)
        end

        it 'calls find on the next directory in the search chain' do
          expect(directory.find('sub_dir/file')).to be(file)
        end

        it 'should remove any leading / in the path' do
          expect(directory.find('/sub_dir/file')).to be(file)
        end
      end

      describe '#parent=' do
        let(:parent) { described_class.new('parent') }

        it 'sets the .. entry in entries list' do
          directory.parent = parent
          expect(directory.entries).to include('..' => parent)
        end

        it 'sets the parent directory' do
          directory.parent = parent
          expect(directory.parent).to be(parent)
        end
      end

      describe '#path' do
        let(:root) { described_class.new('/') }

        it 'returns the directory path' do
          directory.parent = root
          expect(directory.path).to eq('/test')
        end

        context 'when the directory is /' do
          it 'returns /' do
            expect(root.path).to eq('/')
          end
        end
      end

      describe '#paths' do
        before do
          subdir = described_class.new('subdir')
          directory.add_entry(subdir)
          subdir.add_entry File.new('file1')
          subdir.add_entry File.new('file2')
        end

        it 'returns the path of the directory and its entries recursively' do
          expect(directory.paths).to eq \
            %w[test test/subdir test/subdir/file1 test/subdir/file2]
        end
      end

      describe '#remove_entry' do
        let(:file) { File.new('file') }

        it 'removes an entry from the entries list' do
          directory.add_entry file
          directory.remove_entry file
          expect(directory.entries).not_to have_value(file)
        end
      end

      describe '#type' do
        it "returns 'directory'" do
          expect(directory.type).to eq('directory')
        end
      end
    end
  end
end
