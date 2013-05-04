require 'spec_helper'

module FsFaker
  describe File do
    let(:fs) { FileSystem.instance }
    let(:random_string) { ('a'..'z').to_a.sample(rand 100).join }

    describe '.chmod' do
      it "changes permission bits on the named file" do
        fs.touch '/some-file'
        File.chmod(0777, '/some-file')
        File.stat('/some-file').mode.should be(0100777)
      end

      it "changes permission bits on the named files (in list)" do
        fs.touch '/some-file', '/some-file2'
        File.chmod(0777, '/some-file', '/some-file2')
        File.stat('/some-file2').mode.should be(0100777)
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

      context "when no mode is given" do
        it "defaults to read-only access" do
          file = File.open('/test-file')
          file.opening_mode.should be(File::RDONLY)
        end
      end

      context "when a mode is given" do
        context "when the mode indicates file creation" do
          it "creates the file" do
            File.open('/test-file', 'w')
            expect { fs.find!('/test-file') }.not_to raise_error
          end
        end

        context "when the mode does not indicate file creation" do
          it "does not create the file" do
            File.open('/test-file', 'r')
            expect { fs.find!('/test-file') }.to raise_error
          end
        end
      end

      context "when no block is given" do
        it "returns a File instance" do
          File.open('/test-file').should be_a(File)
        end
      end

      context "when a block is given" do
        it "passes the open file to the block" do
          fs.touch('/test-file')
          klass = File.open('/test-file') { |f| f.class }
          klass.should == File
        end

        # it "returns the return value of the block" do
        #   value = File.open('/test-file') { 42 }
        #   value.should be(42)
        # end

        it "ensures the file is closed whatever happens in the block" do
          fs.touch('/test-file')
          file = File.new('/test-file')
          File.stub(:new).and_return(file)

          file.should_receive(:close)
          File.open('/test-file') {}
        end
      end
    end

    describe "#close" do
      it "closes the file stream" do
        fs.touch('/test-file')
        file = File.open('/test-file')
        file.close
        file.should be_closed
      end
    end

    describe "#closed?" do
      before do
        fs.touch('/test-file')
      end

      it "returns true when the file is closed" do
        file = File.open('/test-file')
        file.close
        file.closed?.should be_true
      end

      it "returns false when the file is open" do
        file = File.open('/test-file')
        file.closed?.should be_false
        file.close
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

    describe "#puts" do
      it "appends content to the file" do
        file = File.new('/test-file', 'w')
        file.puts "test"
        file.close
        file.content.to_s.should == "test\n"
      end

      it "does not override the file's content" do
        file = File.new('/test-file', 'w')
        file.puts "test"
        file.puts "test"
        file.close
        file.content.to_s.should == "test\ntest\n"
      end

      it "raises an exception if the file is not writable" do
        file = File.new('/test-file')
        expect { file.puts "test" }.to raise_error(IOError)
      end
    end

    describe ".size" do
      it "returns the size of the file" do
        File.open('/test-file', 'w') { |f| f.puts random_string }
        File.size('/test-file').should == random_string.size + 1
      end
    end

    describe "#read" do
      let(:file) { File.new('/test-file') }

      before :each do
        File.open('/test-file', 'w') { |f| f.puts random_string }
      end

      context "when no length is given" do
        it "returns the content of the named file" do
          file.read.should == random_string + "\n"
        end

        it "returns an empty string if called a second time" do
          file.read
          file.read.should be_empty
        end
      end

      context "when a length is given" do
        it "returns a string of the given length" do
          file.read(2).should == random_string[0, 2]
        end

        it "returns nil when there is nothing more to read" do
          file.read(1000)
          file.read(1000).should be_nil
        end
      end

      context "when a buffer is given" do
        it "fills the buffer with the read content" do
          buffer = String.new
          file.read(2, buffer)
          buffer.should == random_string[0, 2]
        end
      end
    end

    describe "#size" do
      it "returns the size of the file" do
        File.open('/test-file', 'w') { |f| f.puts random_string }
        File.new('/test-file').size.should == random_string.size + 1
      end
    end
  end
end
