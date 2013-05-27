require 'spec_helper'

module FsFaker
  module Fake
    describe Symlink do
      let(:fs) { FileSystem.instance }

      describe '#target' do
        it "returns the target of the symlink" do
          s = Symlink.new('/test-link', '/test-file')
          s.target.should == '/test-file'
        end
      end

      describe '#last_target' do
        it "returns the target if it's not a symlink" do
          fs.touch '/test-file'
          target = fs.find!('/test-file')

          s = Symlink.new('/test-link', '/test-file')

          s.last_target.should == target
        end

        it "returns the last target of the chain" do
          fs.touch '/test-file'
          target = fs.find!('/test-file')

          fs.symlink '/test-file', '/test-link'
          s = Symlink.new('/test-link2', '/test-link')

          s.last_target.should == target
        end
      end

      describe '#content' do
        it "returns the target's content" do
          FsFaker::File.open('/test-file', 'w') { |f| f.puts "test" }
          s = Symlink.new('/test-link', '/test-file')
          s.content.should be(s.last_target.content)
        end
      end
    end
  end
end