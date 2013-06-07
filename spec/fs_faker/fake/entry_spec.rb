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

      it "has a atime attribute accessor" do
        entry.atime = time
        entry.atime.should == time
      end

      it "has a mtime attribute accessor" do
        entry.atime = time
        entry.atime.should == time
      end

      it "has a uid attribute accessor" do
        entry.uid = 42
        entry.uid.should == 42
      end

      it "has a gid attribute accessor" do
        entry.gid = 42
        entry.gid.should == 42
      end

      it "has a parent attribute accessor" do
        parent = Directory.new('/parent')
        entry.parent = parent
        entry.parent.should be(parent)
      end

      it "sets its default uid to the current user's uid" do
        entry.uid.should == Etc.getpwuid.uid
      end

      it "sets its default gid to the current user's gid" do
        entry.gid.should == Etc.getpwuid.gid
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

      describe '.find' do
        it "raises an error" do
          expect { entry.find('test') }.to raise_error(Errno::ENOTDIR)
        end
      end

      describe ".delete" do
        it "removes the entry from its parent" do
          parent = Directory.new('/parent')
          entry.parent = parent
          entry.delete
          parent.entries.should_not have_value(entry)
        end
      end

      describe ".path" do
        let(:entry) { Entry.new('test') }

        it "returns the name of the entry" do
          expect(entry.path).to eq('test')
        end

        context "when the entry as a parent" do
          it "returns the complete path of the entry" do
            entry.parent = Entry.new('/')
            expect(entry.path).to eq('/test')
          end
        end
      end
    end
  end
end
