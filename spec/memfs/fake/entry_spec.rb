require 'spec_helper'

module MemFs
  module Fake
    describe Entry do
      let(:entry) { Entry.new('test') }
      let(:parent) { Directory.new('parent') }

      before(:each) do
        parent.parent = Directory.new('/')
        entry.parent = parent
      end

      shared_examples 'it has accessors for' do |attribute, value, expected_value|
        expected_value ||= value

        it attribute do
          entry.send(:"#{attribute}=", value)
          expect(entry.send(attribute)).to eq(expected_value)
        end
      end

      it_behaves_like 'it has accessors for', :name, 'test'
      it_behaves_like 'it has accessors for', :atime, Time.now - 5000
      it_behaves_like 'it has accessors for', :mtime, Time.now - 5000
      it_behaves_like 'it has accessors for', :uid, 42
      it_behaves_like 'it has accessors for', :gid, 42
      it_behaves_like 'it has accessors for', :mode, 0777, 0100777
      it_behaves_like 'it has accessors for', :parent, Directory.new('/parent')

      describe ".delete" do
        it "removes the entry from its parent" do
          entry.delete
          expect(parent.entries).not_to have_value(entry)
        end
      end

      describe '.dereferenced' do
        it "returns the entry itself" do
          expect(entry.dereferenced).to be(entry)
        end
      end

      describe '.find' do
        it "raises an error" do
          expect { entry.find('test') }.to raise_error(Errno::ENOTDIR)
        end
      end

      describe ".new" do
        it "sets its default uid to the current user's uid" do
          expect(entry.uid).to eq(Etc.getpwuid.uid)
        end

        it "sets its default gid to the current user's gid" do
          expect(entry.gid).to eq(Etc.getpwuid.gid)
        end

        it "extract its name from the path passed as argument" do
          expect(entry.name).to eq('test')
        end

        it "sets an empty string as name if none is given" do
          expect(Entry.new.name).to be_empty
        end

        it "sets the access time" do
          expect(Entry.new.atime).to be_a(Time)
        end

        it "sets the modification time" do
          expect(entry.mtime).to be_a(Time)
        end

        it "sets atime and mtime to the same value" do
          expect(entry.atime).to eq(entry.mtime)
        end
      end

      describe ".path" do
        it "returns the complete path of the entry" do
          expect(entry.path).to eq('/parent/test')
        end
      end

      describe "#dev" do
        it "returns an integer representing the device on which the entry resides" do
          expect(entry.dev).to be_a(Fixnum)
        end
      end

      describe "#ino" do
        it "Returns the inode number for the entry" do
          expect(entry.ino).to be_a(Fixnum)
        end
      end

      describe "#touch" do
        let(:time) { Time.now - 5000 }

        before :each do
          entry.atime = time
          entry.mtime = time
        end

        it "sets the access time to now" do
          entry.touch
          expect(entry.atime).not_to eq(time)
        end

        it "sets the modification time to now" do
          entry.touch
          expect(entry.mtime).not_to eq(time)
        end
      end
    end
  end
end
