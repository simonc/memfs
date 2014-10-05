require 'spec_helper'

module MemFs
  describe Pathname do
    describe 'Class Methods' do
      subject { MemFs::Pathname }

      describe '.new' do
        it 'creates a Pathname object from the given path' do
          pathname = subject.new('some/path')
          expect(pathname.to_s).to eq 'some/path'
        end

        context 'when the given path is not a string' do
          it 'creates a Pathname object from the string representation of the path' do
            path = MemFs::Pathname.new('some/path')
            pathname = MemFs::Pathname.new(path)
            expect(pathname.to_s).to eq 'some/path'
          end
        end
      end
    end

    describe "Instance Methods" do
      subject(:pathname) { MemFs::Pathname.new('some/path') }

      describe '#to_str' do
        it 'can be converted to a string object' do
          expect('test ' + pathname).to eq 'test some/path'
        end
      end

      describe '#to_s' do
        it "returns the path as a String" do
          expect(pathname.to_s).to eq 'some/path'
        end
      end
    end
  end
end
