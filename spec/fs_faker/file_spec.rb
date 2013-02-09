require 'spec_helper'

module FsFaker
  describe File do
    let(:fs) { FileSystem.instance }

    describe '.chmod' do
      it "changes permission bits on the named file" do
        fs.touch '/some-file'
        File.chmod(0777, '/some-file')
        File.stat('/some-file').mode.should be(0100777)
      end
    end

    describe '.directory?' do
      it "returns true if an entry is a directory" do
        fs.mkdir('/test')
        File.directory?('/test').should be_true
      end
    end

    describe '.path' do
      it "returns the string representation of the path" do
        File.path('/some/test').should == '/some/test'
      end

      it "returns the string representation of the path of a Pathname" do
        File.path(Pathname.new('/some/test')).should == '/some/test'
      end
    end

    describe '.lstat' do
      it "returns a File::Stat object for the named file" do
        fs.touch('/test-file')
        File.lstat('/test-file').should be_a(File::Stat)
      end

      it "does not follow the last symbolic link" do
        fs.touch('/test-file')
        File.symlink('/test-file', '/test-link')
        File.lstat('/test-link').symlink?.should be_true
      end

      it "raises an error if the named file does not exist" do
        expect { File.lstat('/no-file') }.to raise_error(Errno::ENOENT)
      end

      it "doesn't raise an error if the named file is a symlink and its target doesn't exist" do
        File.symlink('/test-file', '/test-link')
        expect { File.lstat('/test-link') }.not_to raise_error(Errno::ENOENT)
      end
    end

    describe '.stat' do
      it "returns a File::Stat object for the named file" do
        fs.touch('/test-file')
        File.stat('/test-file').should be_a(File::Stat)
      end

      it "follows the last symbolic link" do
        fs.touch('/test-file')
        File.symlink('/test-file', '/test-link')
        File.stat('/test-link').symlink?.should be_false
      end

      it "raises an error if the named file does not exist" do
        expect { File.stat('/no-file') }.to raise_error(Errno::ENOENT)
      end

      it "raises an error if the named file is a symlink and its target doesn't exist" do
        File.symlink('/test-file', '/test-link')
        expect { File.stat('/test-link') }.to raise_error(Errno::ENOENT)
      end

      it "always returns a new object" do
        fs.touch('/test-file')
        stat = File.stat('/test-file')
        File.stat('/test-file').should_not be(stat)
      end
    end

    describe '.symlink' do
      it "creates a symbolic link named new_name" do
        fs.touch('/test-file')
        File.symlink('/test-file', '/test-link')
        File.symlink?('/test-link').should be_true
      end

      it "creates a symbolic link that points to an entry named old_name" do
        File.symlink('/test-file', '/test-link')
        fs.find!('/test-link').target.should == '/test-file'
      end

      it "creates a symbolic link even if the target does not exist" do
        File.symlink('/test-file', '/test-link')
        File.symlink?('/test-link').should be_true
      end

      it "returns 0" do
        File.symlink('/test-file', '/test-link').should == 0
      end
    end

    describe '.symlink?' do
      it "returns true if the entry is a symlink" do
        File.symlink('/test-file', '/test-link')
        File.symlink?('/test-link').should be_true
      end

      it "returns false if the entry is not a symlink" do
        fs.touch('/test-file')
        File.symlink?('/test-file').should be_false
      end

      it "returns false if the entry doesn't exist" do
        File.symlink?('/test-file').should be_false
      end
    end

    describe '.umask' do
      it "returns the current umask value for this process" do
        File.umask.should be(0022)
      end

      context "when the optional argument is given" do
        it "sets the umask to that value" do
          File.umask 0777
          File.umask.should be(0777)
        end

        it "return the previous value" do
          File.umask(0777).should be(0022)
        end
      end
    end

    describe '.utime' do
      let(:time) { Time.now - 500000 }

      it "sets the access time of each named file to the first argument" do
        fs.touch('/test-file')
        File.utime(time, time, '/test-file')
        File.atime('/test-file').should == time
      end

      it "sets the modification time of each named file to the second argument" do
        fs.touch('/test-file')
        File.utime(time, time, '/test-file')
        File.mtime('/test-file').should == time
      end

      it "returns the number of file names in the argument list" do
        fs.touch('/test-file', '/test-file2')
        File.utime(time, time, '/test-file', '/test-file2').should be(2)
      end

      it "raises en error if the entry doesn't exist" do
        expect { File.utime(time, time, '/test-file') }.to raise_error(Errno::ENOENT)
      end
    end

    describe '.atime' do
      it "returns the last access time for the named file as a Time object" do
        fs.touch('/test-file')
        File.atime('/test-file').should be_a(Time)
      end

      it "raises an error if the entry doesn't exist" do
        expect { File.atime('/test-file') }.to raise_error(Errno::ENOENT)
      end

      context "when the entry is a symlink" do
        let(:time) { Time.now - 500000 }

        it "returns the last access time of the last target of the link chain" do
          fs.touch('/test-file')
          fs.find!('/test-file').atime = time
          File.symlink('/test-file', '/test-link')
          File.symlink('/test-link', '/test-link2')
          File.atime('/test-link2').should == time
        end
      end
    end

    describe ".lchmod" do
      before :each do
        fs.touch('/test-file')
        fs.symlink('/test-file', '/test-link')
      end

      context "when the named file is a regular file" do
        it "acts like chmod" do
          File.lchmod(0777, '/test-file')
          File.stat('/test-file').mode.should be(0100777)
        end
      end

      context "when the named file is a symlink" do
        it "changes permission bits on the symlink" do
          File.lchmod(0777, '/test-link')
          File.lstat('/test-link').mode.should be(0100777)
        end

        it "doesn't change permission bits on the link's target" do
          File.lchmod(0777, '/test-link')
          File.stat('/test-file').mode.should be(0100644)
        end
      end
    end

    # describe '.mtime' do
    #   it "returns the last modification time for the named file as a Time object" do
    #     fs.touch('/test-file')
    #     File.mtime('/test-file').should be_a(Time)
    #   end
    # 
    #   it "raises an error if the entry doesn't exist" do
    #     expect { File.mtime('/test-file') }.to raise_error(Errno::ENOENT)
    #   end
    # 
    #   context "when the entry is a symlink" do
    #     let(:time) { Time.now - 500000 }
    # 
    #     it "returns the last modification time of the last target of the link chain" do
    #       fs.touch('/test-file')
    #       fs.find!('/test-file').mtime = time
    #       File.symlink('/test-file', '/test-link')
    #       File.symlink('/test-link', '/test-link2')
    #       File.mtime('/test-link2').should == time
    #     end
    #   end
    # end

    describe '.open' do
      it "creates the file when called with mode a" do
        File.open('/test-file', 'a')
        expect { fs.find!('/test-file') }.not_to raise_error
      end
      # context "when no block is given" do
      #   it "is a synonym of new if no argument is passed" do
      #     File.should_receive(:new).with('/test-file', 'r', 0666)
      #     File.open('/test-file', 'r', 0666)
      #   end
      # 
      #   it "returns a File instance" do
      #     File.open('/test-file').should be_a(File)
      #   end
      # end
      # 
      context "when a block is given" do
        it "passes the open file to the block" do
          klass = File.open('/test-file') { |f| f.class }
          klass.should == File
        end

        # it "returns the return value of the block" do
        #   value = File.open('/test-file') { 42 }
        #   value.should be(42)
        # end
        # 
        # it "ensures the file is closed whatever happens in the block" do
        #   file = File.new('/test-file')
        #   File.stub(:new).and_return(file)
        #   file.should_receive(:close)
        #   File.open('/test-file') {}
        # end
      end
    end

    # describe '.new' do
    #   it "accepts string or integer as mode value"
    # 
    #   it "raises an error if no argument is given" do
    #     expect { File.open }.to raise_error(ArgumentError)
    #   end
    # 
    #   it "raises an error if too many arguments are given" do
    #     expect { File.open(1,2,3,4) }.to raise_error(ArgumentError)
    #   end
    # 
    #   it "changes the mtime of the file if the mode is w or w+"
    # end

    describe ".join" do
      it "Returns a new string formed by joining the strings using File::SEPARATOR" do
        File.join('a', 'b', 'c').should == 'a/b/c'
      end
    end

    describe ".chown" do
      before :each do
        fs.clear!
        fs.touch '/test-file', '/test-file2'
      end

      it "changes the owner of the named file to the given numeric owner id" do
        File.chown(42, nil, '/test-file')
        File.stat('/test-file').uid.should be(42)
      end

      it "changes owner on the named files (in list)" do
        File.chown(42, nil, '/test-file', '/test-file2')
        File.stat('/test-file2').uid.should be(42)
      end

      it "changes the group of the named file to the given numeric group id" do
        File.chown(nil, 42, '/test-file')
        File.stat('/test-file').gid.should be(42)
      end

      it "returns the number of files" do
        File.chown(42, 42, '/test-file', '/test-file2').should be(2)
      end

      it "ignores nil user id" do
        previous_uid = File.stat('/test-file').uid

        File.chown(nil, 42, '/test-file')
        File.stat('/test-file').uid.should == previous_uid
      end

      it "ignores nil group id" do
        previous_gid = File.stat('/test-file').gid

        File.chown(42, nil, '/test-file')
        File.stat('/test-file').gid.should == previous_gid
      end

      it "ignores -1 user id" do
        previous_uid = File.stat('/test-file').uid

        File.chown(-1, 42, '/test-file')
        File.stat('/test-file').uid.should == previous_uid
      end

      it "ignores -1 group id" do
        previous_gid = File.stat('/test-file').gid

        File.chown(42, -1, '/test-file')
        File.stat('/test-file').gid.should == previous_gid
      end

      context "when the named entry is a symlink" do
        before :each do
          fs.symlink '/test-file', '/test-link'
        end

        it "changes the owner on the last target of the link chain" do
          File.chown(42, nil, '/test-link')
          File.stat('/test-file').uid.should be(42)
        end

        it "changes the group on the last target of the link chain" do
          File.chown(nil, 42, '/test-link')
          File.stat('/test-file').gid.should be(42)
        end

        it "doesn't change the owner of the symlink" do
          File.chown(42, nil, '/test-link')
          File.lstat('/test-link').uid.should_not be(42)
        end

        it "doesn't change the group of the symlink" do
          File.chown(nil, 42, '/test-link')
          File.lstat('/test-link').gid.should_not be(42)
        end
      end
    end
  end
end
