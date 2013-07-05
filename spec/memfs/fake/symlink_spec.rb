require 'spec_helper'

module MemFs
  module Fake
    describe Symlink do
      describe '#content' do
        it "returns the target's content" do
          MemFs::File.open('/test-file', 'w') { |f| f.puts "test" }
          s = Symlink.new('/test-link', '/test-file')
          expect(s.content).to be(s.dereferenced.content)
        end
      end

      describe '#dereferenced' do
        it "returns the target if it's not a symlink" do
          fs.touch '/test-file'
          target = fs.find!('/test-file')

          s = Symlink.new('/test-link', '/test-file')

          expect(s.dereferenced).to eq(target)
        end

        it "returns the last target of the chain" do
          fs.touch '/test-file'
          target = fs.find!('/test-file')

          fs.symlink '/test-file', '/test-link'
          s = Symlink.new('/test-link2', '/test-link')

          expect(s.dereferenced).to eq(target)
        end
      end

      describe '#target' do
        it "returns the target of the symlink" do
          s = Symlink.new('/test-link', '/test-file')
          expect(s.target).to eq('/test-file')
        end
      end
    end
  end
end
