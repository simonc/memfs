require 'spec_helper'

module FsFaker
  describe File::Stat do
    let(:fs) { FileSystem.instance }

    describe '.new' do
      context "when optional follow_symlink argument is set to true" do
        it "raises an error if the end-of-links-chain target doesn't exist" do
          fs.symlink('/test-file', '/test-link')
          expect { File::Stat.new('/test-link', true) }.to raise_error(Errno::ENOENT)
        end
      end
    end

    describe '#entry' do
      it "returns the comcerned entry" do
        entry = fs.touch('/test-file')
        stat = File::Stat.new('/test-file')
        stat.entry.should be_a(Fake::File)
      end
    end

    describe '#symlink?' do
      it "returns true if the entry is a symlink" do
        fs.touch('/test-file')
        fs.symlink('/test-file', '/test-link')
        File::Stat.new('/test-link').symlink?.should be_true
      end

      it "returns false if the entry is not a symlink" do
        fs.touch('/test-file')
        File::Stat.new('/test-file').symlink?.should be_false
      end
    end

    describe '#mode' do
      it "returns an integer representing the permission bits of stat" do
        fs.touch('/test-file')
        fs.chmod(0777, '/test-file')
        File::Stat.new('/test-file').mode.should be(0100777)
      end
    end

    describe '#atime' do
      let(:time) { Time.now - 500000 }

      it "returns the access time of the entry" do
        fs.touch('/test-file')
        entry = fs.find!('/test-file')
        entry.atime = time
        File::Stat.new('/test-file').atime.should == time
      end

      context "when the entry is a symlink" do
        context "and the optional follow_symlink argument is true" do
          it "returns the access time of the last target of the link chain" do
            fs.touch('/test-file')
            entry = fs.find!('/test-file')
            entry.atime = time
            fs.symlink('/test-file', '/test-link')
            File::Stat.new('/test-link', true).atime.should == time
          end
        end

        context "and the optional follow_symlink argument is false" do
          it "returns the access time of the symlink itself" do
            fs.touch('/test-file')
            entry = fs.find!('/test-file')
            entry.atime = time
            fs.symlink('/test-file', '/test-link')
            File::Stat.new('/test-link').atime.should_not == time
          end
        end
      end
    end
  end
end
