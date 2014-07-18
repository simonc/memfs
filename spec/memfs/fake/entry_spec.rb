require 'spec_helper'

module MemFs
  module Fake
    describe Entry do
      let(:entry) { Entry.new('test') }
      let(:parent) { Directory.new('parent') }
      let(:time) { Time.now - 5000 }

      before(:each) do
        parent.parent = Directory.new('/')
        entry.parent = parent
      end

      shared_examples 'it has accessors for' do |attribute|
        let(:expected) { value }

        it attribute do
          entry.send(:"#{attribute}=", value)
          expect(entry.public_send(attribute)).to eq(expected)
        end
      end

      it_behaves_like 'it has accessors for', :name do
        let(:value) { 'test' }
      end

      it_behaves_like 'it has accessors for', :atime do
        let(:value) { time }
      end

      it_behaves_like 'it has accessors for', :block_device do
        let(:value) { true }
      end

      it_behaves_like 'it has accessors for', :character_device do
        let(:value) { true }
      end

      it_behaves_like 'it has accessors for', :ctime do
        let(:value) { time }
      end

      it_behaves_like 'it has accessors for', :mtime do
        let(:value) { time }
      end

      it_behaves_like 'it has accessors for', :uid do
        let(:value) { 42 }
      end

      it_behaves_like 'it has accessors for', :gid do
        let(:value) { 42 }
      end

      it_behaves_like 'it has accessors for', :mode do
        let(:value) { 0777 }
        let(:expected) { 0100777 }
      end

      it_behaves_like 'it has accessors for', :parent do
        let(:value) { parent }
      end

      describe ".new" do
        it "sets its default uid to the current user's uid" do
          expect(entry.uid).to eq(Process.euid)
        end

        it "sets its default gid to the current user's gid" do
          expect(entry.gid).to eq(Process.egid)
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

      describe "#delete" do
        it "removes the entry from its parent" do
          entry.delete
          expect(parent.entries).not_to have_value(entry)
        end
      end

      describe '#dereferenced' do
        it "returns the entry itself" do
          expect(entry.dereferenced).to be(entry)
        end
      end

      describe "#dereferenced_name" do
        it "returns the entry name" do
          expect(entry.dereferenced_name).to eq('test')
        end
      end

      describe "#dereferenced_path" do
        it "returns the entry path" do
          expect(entry.dereferenced_path).to eq('/parent/test')
        end
      end

      describe '#find' do
        it "raises an error" do
          expect { entry.find('test') }.to raise_error(Errno::ENOTDIR)
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

      describe "#path" do
        it "returns the complete path of the entry" do
          expect(entry.path).to eq('/parent/test')
        end
      end

      describe 'paths' do
        it 'returns an array containing the entry path' do
          expect(entry.paths).to eq ['/parent/test']
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

      describe "#type" do
        it "returns 'unknown" do
          expect(entry.type).to eq('unknown')
        end
      end
    end
  end
end
