require 'spec_helper'

module FsFaker
  module Fake
    describe Entry do
      let(:entry) { Entry.new }
      let(:time) { Time.now - 5000 }

      it "has a name attribute accessor" do
        entry.name = 'test'
        entry.name.should == 'test'
      end

      it "has a mode attribute accessor" do
        entry.mode.should be(33188)
      end

      it "has a path attribute accessor" do
        entry.path = '/test'
        entry.path.should == '/test'
      end

      it "has a atime attribute accessor" do
        entry.atime = time
        entry.atime.should == time
      end

      it "has a mtime attribute accessor" do
        entry.atime = time
        entry.atime.should == time
      end

      describe '#mode=' do
        it "sets the mode as binary value" do
          entry.mode = 0777
          entry.mode.should be(0100777)
        end
      end

      describe "#touch" do
        before :each do
          entry.atime = time
          entry.mtime = time
        end

        it "sets the access time to now" do
          entry.touch
          entry.atime.should_not == time
        end

        it "sets the modification time to now" do
          entry.touch
          entry.mtime.should_not == time
        end
      end

      describe '.initialize' do
        it "extract its name from the path passed as argument" do
          Entry.new('/test').name.should == 'test'
        end

        it "sets an empty string as name if none is given" do
          Entry.new.name.should == ''
        end

        it "set its path as the path passed as argument" do
          Entry.new('/test').path.should == '/test'
        end

        it "sets the access time" do
          Entry.new.atime.should be_a(Time)
        end

        it "sets the modification time" do
          entry.mtime.should be_a(Time)
        end

        it "sets atime and mtime to the same value" do
          entry.atime.should be(entry.mtime)
        end
      end

      describe '.last_target' do
        it "returns the entry itself" do
          entry.last_target.should be(entry)
        end
      end
    end
  end
end
