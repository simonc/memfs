require 'spec_helper'

module MemFs
  describe File do
    let(:file) { File.new('/test-file') }
    let(:random_string) { ('a'..'z').to_a.sample(10).join }

    before :each do
      fs.mkdir '/test-dir'
      fs.touch '/test-file', '/test-file2'
      File.symlink '/test-file', '/test-link'
      File.symlink '/no-file', '/no-link'
    end

    describe '.chmod' do
      it "changes permission bits on the named file" do
        File.chmod(0777, '/test-file')
        File.stat('/test-file').mode.should be(0100777)
      end

      it "changes permission bits on the named files (in list)" do
        File.chmod(0777, '/test-file', '/test-file2')
        File.stat('/test-file2').mode.should be(0100777)
      end
    end

    describe '.directory?' do
      context "when the named entry is a directory" do
        it "returns true" do
          File.directory?('/test-dir').should be_true
        end
      end

      context "when the named entry is not a directory" do
        it "returns false" do
          File.directory?('/test-file').should be_false
        end
      end
    end

    describe '.path' do
      context "when the path is a string" do
        let(:path) { '/some/path' }

        it "returns the string representation of the path" do
          File.path(path).should == '/some/path'
        end
      end

      context "when the path is a Pathname" do
        let(:path) { Pathname.new('/some/path') }

        it "returns the string representation of the path" do
          File.path(path).should == '/some/path'
        end
      end
    end

    describe '.lstat' do
      it "returns a File::Stat object for the named file" do
        File.lstat('/test-file').should be_a(File::Stat)
      end

      context "when the named file does not exist" do
        it "raises an exception" do
          expect { File.lstat('/no-file') }.to raise_error(Errno::ENOENT)
        end
      end

      context "when the named file is a symlink" do
        it "does not follow the last symbolic link" do
          File.lstat('/test-link').symlink?.should be_true
        end

        context "and its target does not exist" do
          it "ignores errors" do
            expect {
              File.lstat('/no-link')
            }.not_to raise_error(Errno::ENOENT)
          end
        end
      end
    end

    describe '.stat' do
      it "returns a File::Stat object for the named file" do
        File.stat('/test-file').should be_a(File::Stat)
      end

      it "follows the last symbolic link" do
        File.stat('/test-link').symlink?.should be_false
      end

      context "when the named file does not exist" do
        it "raises an exception" do
          expect { File.stat('/no-file') }.to raise_error(Errno::ENOENT)
        end
      end

      context "when the named file is a symlink" do
        context "and its target does not exist" do
          it "raises an exception" do
            expect { File.stat('/no-link') }.to raise_error(Errno::ENOENT)
          end
        end
      end

      it "always returns a new object" do
        stat = File.stat('/test-file')
        File.stat('/test-file').should_not be(stat)
      end
    end

    describe '.symlink' do
      it "creates a symbolic link named new_name" do
        File.symlink?('/test-link').should be_true
      end

      it "creates a symbolic link that points to an entry named old_name" do
        fs.find!('/test-link').target.should == '/test-file'
      end

      context "when the target does not exist" do
        it "creates a symbolic link" do
          File.symlink?('/no-link').should be_true
        end
      end

      it "returns 0" do
        File.symlink('/test-file', '/new-link').should == 0
      end
    end

    describe '.symlink?' do
      context "when the named entry is a symlink" do
        it "returns true" do
          File.symlink?('/test-link').should be_true
        end
      end

      context "when the named entry is not a symlink" do
        it "returns false" do
          File.symlink?('/test-file').should be_false
        end
      end

      context "when the named entry does not exist" do
        it "returns false" do
          File.symlink?('/no-file').should be_false
        end
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
        File.utime(time, time, '/test-file')
        File.atime('/test-file').should == time
      end

      it "sets the modification time of each named file to the second argument" do
        File.utime(time, time, '/test-file')
        File.mtime('/test-file').should == time
      end

      it "returns the number of file names in the argument list" do
        File.utime(time, time, '/test-file', '/test-file2').should be(2)
      end

      it "raises en error if the entry does not exist" do
        expect { File.utime(time, time, '/no-file') }.to raise_error(Errno::ENOENT)
      end
    end

    describe '.atime' do
      it "returns the last access time for the named file as a Time object" do
        File.atime('/test-file').should be_a(Time)
      end

      it "raises an error if the entry does not exist" do
        expect { File.atime('/no-file') }.to raise_error(Errno::ENOENT)
      end

      context "when the entry is a symlink" do
        let(:time) { Time.now - 500000 }

        it "returns the last access time of the last target of the link chain" do
          fs.find!('/test-file').atime = time
          File.symlink('/test-link', '/test-link2')
          File.atime('/test-link2').should == time
        end
      end
    end

    describe ".lchmod" do
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

        it "does not change permission bits on the link's target" do
          File.lchmod(0777, '/test-link')
          File.stat('/test-file').mode.should be(0100644)
        end
      end
    end

    describe '.mtime' do
      it "returns the last modification time for the named file as a Time object" do
        File.mtime('/test-file').should be_a(Time)
      end

      it "raises an error if the entry does not exist" do
        expect { File.mtime('/no-file') }.to raise_error(Errno::ENOENT)
      end

      context "when the entry is a symlink" do
        let(:time) { Time.now - 500000 }

        it "returns the last modification time of the last target of the link chain" do
          fs.find!('/test-file').mtime = time
          File.symlink('/test-link', '/test-link2')
          File.mtime('/test-link2').should == time
        end
      end
    end

    describe '.open' do
      it "creates the file when called with mode a" do
        File.open('/new-file', 'a')
        expect(File.exists?('/new-file')).to be_true
      end

      context "when no mode is given" do
        it "defaults to read-only access" do
          file = File.open('/test-file')
          file.opening_mode.should be(File::RDONLY)
          file.close
        end
      end

      context "when a mode is given" do
        context "when the mode indicates file creation" do
          it "creates the file" do
            File.open('/new-file', 'w')
            expect(File.exists?('/new-file')).to be_true
          end
        end

        context "when the mode does not indicate file creation" do
          it "does not create the file" do
            File.open('/new-file', 'r')
            expect(File.exists?('/new-file')).to be_false
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
          klass = File.open('/test-file') { |f| f.class }
          klass.should == File
        end

        it "returns the return value of the block" do
          value = File.open('/test-file') { 42 }
          value.should be(42)
        end

        it "ensures the file is closed whatever happens in the block" do
          file = File.new('/test-file')
          File.stub(:new).and_return(file)

          file.should_receive(:close)
          File.open('/test-file') {}
        end
      end
    end

    describe "#close" do
      it "closes the file stream" do
        file = File.open('/test-file')
        file.close
        file.should be_closed
      end
    end

    describe "#closed?" do
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
        it "changes the owner on the last target of the link chain" do
          File.chown(42, nil, '/test-link')
          File.stat('/test-file').uid.should be(42)
        end

        it "changes the group on the last target of the link chain" do
          File.chown(nil, 42, '/test-link')
          File.stat('/test-file').gid.should be(42)
        end

        it "does not change the owner of the symlink" do
          File.chown(42, nil, '/test-link')
          File.lstat('/test-link').uid.should_not be(42)
        end

        it "does not change the group of the symlink" do
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

    describe ".identical?" do
      before :each do
        File.open('/test-file', 'w') { |f| f.puts 'test' }
        File.open('/test-file2', 'w') { |f| f.puts 'test' }
        File.symlink '/test-file', '/test-file-link'
        File.symlink '/test-file', '/test-file-link2'
        File.symlink '/test-file2', '/test-file2-link'
      end

      context "when two paths represent the same path" do
        it "returns true" do
          File.identical?('/test-file', '/test-file').should be_true
        end
      end

      context "when two paths do not represent the same file" do
        it "returns false" do
          File.identical?('/test-file', '/test-file2').should be_false
        end
      end

      context "when one of the paths does not exist" do
        it "returns false" do
          File.identical?('/test-file', '/no-file').should be_false
        end
      end

      context "when a path is a symlink" do
        context "and the linked file is the same as the other path" do
          it "returns true" do
            File.identical?('/test-file', '/test-file-link').should be_true
          end
        end

        context "and the linked file is different from the other path" do
          it "returns false" do
            File.identical?('/test-file2', '/test-file-link').should be_false
          end
        end
      end

      context "when the two paths are symlinks" do
        context "and both links point to the same file" do
          it "returns true" do
            File.identical?('/test-file-link', '/test-file-link2').should be_true
          end
        end

        context "and both links do not point to the same file" do
          it "returns false" do
            File.identical?('/test-file-link', '/test-file2-link').should be_false
          end
        end
      end
    end

    describe "#stat" do
      it "returns the +Stat+ object of the file" do
        file = File.new('/test-file')
        file.stat == File.stat('/test-file')
      end
    end

    describe "#path" do
      it "returns the path of the file" do
        file = File.new('/test-file')
        file.path.should == '/test-file'
      end
    end

    describe "#write" do
      it "writes the given string to file" do
        File.open('/test-file', 'w') { |f| f.write "test" }
        File.read('/test-file').should == "test"
      end

      it "returns the number of bytes written" do
        file = File.open('/test-file', 'w')
        file.write('test').should be(4)
        file.close
      end

      context "when the file is not opened for writing" do
        it "raises an exception" do
          file = File.open('/test-file')
          expect { file.write('test') }.to raise_error(IOError)
          file.close
        end
      end

      context "when the argument is not a string" do
        it "will be converted to a string using to_s" do
          File.open('/test-file', 'w') { |f| f.write 42 }
          File.read('/test-file').should == '42'
        end
      end
    end

    describe ".read" do
      before :each do
        File.open('/test-file', 'w') { |f| f.puts "test" }
      end

      it "reads the content of the given file" do
        File.read('/test-file').should == "test\n"
      end

      context "when +lenght+ is provided" do
        it "reads only +length+ characters" do
          File.read('/test-file', 2).should == 'te'
        end

        context "when +length+ is bigger than the file size" do
          it "reads until the end of the file" do
            File.read('/test-file', 1000).should == "test\n"
          end
        end
      end

      context "when +offset+ is provided" do
        it "starts reading from the offset" do
          File.read('/test-file', 2, 1).should == 'es'
        end

        it "raises an error if offset is negative" do
          expect {
            File.read('/test-file', 2, -1)
          }.to raise_error(Errno::EINVAL)
        end
      end

      context "when the last argument is a hash" do
        it "passes the contained options to +open+" do
          File.should_receive(:open)
              .with('/test-file', File::RDONLY, encoding: 'UTF-8')
              .and_return(file)
          File.read('/test-file', encoding: 'UTF-8')
        end

        context "when it contains the +open_args+ key" do
          it "takes precedence over the other options" do
            File.should_receive(:open)
                .with('/test-file', 'r')
                .and_return(file)
            File.read('/test-file', mode: 'w', open_args: ['r'])
          end
        end
      end
    end

    describe "#seek" do
      before :each do
        File.open('/test-file', 'w') { |f| f.puts 'test' }
      end

      it "returns zero" do
        file.seek(1).should be(0)
      end

      context "when +whence+ is not provided" do
        it "seeks to the absolute location given by +amount+" do
          file.seek(3)
          file.pos.should be(3)
        end
      end

      context "when +whence+ is IO::SEEK_CUR" do
        it "seeks to +amount+ plus current position" do
          file.read(1)
          file.seek(1, IO::SEEK_CUR)
          file.pos.should be(2)
        end
      end

      context "when +whence+ is IO::SEEK_END" do
        it "seeks to +amount+ plus end of stream" do
          file.seek(-1, IO::SEEK_END)
          file.pos.should be(4)
        end
      end

      context "when +whence+ is IO::SEEK_SET" do
        it "seeks to the absolute location given by +amount+" do
          file.seek(3, IO::SEEK_SET)
          file.pos.should be(3)
        end
      end

      context "when +whence+ is invalid" do
        it "raises an exception" do
          expect { file.seek(0, 42) }.to raise_error(Errno::EINVAL)
        end
      end

      context "if the position ends up to be less than zero" do
        it "raises an exception" do
          expect { file.seek(-1) }.to raise_error(Errno::EINVAL)
        end
      end
    end

    describe "#pos" do
      before :each do
        File.open('/test-file', 'w') { |f| f.puts 'test' }
      end

      it "returns zero when the file was just opened" do
        file.pos.should be_zero
      end

      it "returns the reading offset when some of the file has been read" do
        file.read(2)
        file.pos.should be(2)
      end
    end

    describe ".expand_path" do
      it "converts a pathname to an absolute pathname" do
        fs.chdir('/')
        File.expand_path('test-file').should == "/test-file"
      end

      it "references path from the current working directory" do
        fs.chdir('/test-dir')
        File.expand_path('test-file').should == "/test-dir/test-file"
      end

      context "when +dir_string+ is provided" do
        it "uses +dir_string+ as the stating point" do
          File.expand_path('test-file', '/test').should == "/test/test-file"
        end
      end
    end

    describe ".basename" do
      it "returns the last component of the filename given in +file_name+" do
        File.basename('/path/to/file.txt').should == 'file.txt'
      end

      context "when +suffix+ is given" do
        context "when it is present at the end of +file_name+" do
          it "removes the +suffix+ from the filename basename" do
            File.basename('/path/to/file.txt', '.txt').should == 'file'
          end
        end
      end
    end

    describe ".exists?" do
      it "returns true if the file exists" do
        File.exists?('/test-file').should be_true
      end

      it "returns false if the file does not exist" do
        File.exists?('/no-file').should be_false
      end
    end

    describe ".exist?" do
      it "should be an alias for .exists?" do
        File.method(:exist?).should == File.method(:exists?)
      end
    end

    describe ".dirname" do
      it "returns all components of the filename given in +file_name+ except the last one" do
        File.dirname('/path/to/some/file.txt').should == '/path/to/some'
      end

      it "returns / if file_name is /" do
        File.dirname('/').should == '/'
      end
    end

    describe ".link" do
      before :each do
        File.open('/test-file', 'w') { |f| f.puts 'test' }
      end

      it "creates a new name for an existing file using a hard link" do
        File.link('/test-file', '/new-file')
        File.read('/new-file').should == File.read('/test-file')
      end

      it "returns zero" do
        File.link('/test-file', '/new-file').should == 0
      end

      context "when +old_name+ does not exist" do
        it "raises an exception" do
          expect {
            File.link('/no-file', '/nowhere')
          }.to raise_error(Errno::ENOENT)
        end
      end

      context "when +new_name+ already exists" do
        it "raises an exception" do
          File.open('/test-file2', 'w') { |f| f.puts 'test2' }
          expect {
            File.link('/test-file', '/test-file2')
          }.to raise_error(SystemCallError)
        end
      end
    end

    describe ".unlink" do
      it "deletes the named file" do
        File.unlink('/test-file')
        File.exists?('/test-file').should be_false
      end

      it "returns the number of names passed as arguments" do
        File.unlink('/test-file', '/test-file2').should be(2)
      end

      context "when multiple file names are given" do
        it "deletes the named files" do
          File.unlink('/test-file', '/test-file2')
          expect(File.exists?('/test-file2')).to be_false
        end
      end

      context "when the entry is a directory" do
        it "raises an exception" do
          expect { File.unlink('/test-dir') }.to raise_error(Errno::EPERM)
        end
      end
    end

    describe ".delete" do
      it "is an alias for #unlink" do
        File.method(:delete).should == File.method(:unlink)
      end
    end

    describe ".rename" do
      it "renames the given file to the new name" do
        File.rename('/test-file', '/test-file2')
        expect(File.exists?('/test-file2')).to be_true
      end

      it "returns zero" do
        expect(File.rename('/test-file', '/test-file2')).to eq(0)
      end
    end

    describe "#chown" do
      it "changes the owner of the named file to the given numeric owner id" do
        file.chown(42, nil)
        expect(file.stat.uid).to be(42)
      end

      it "changes owner on the named files (in list)" do
        file.chown(42)
        expect(file.stat.uid).to be(42)
      end

      it "changes the group of the named file to the given numeric group id" do
        file.chown(nil, 42)
        expect(file.stat.gid).to be(42)
      end

      it "returns zero" do
        expect(file.chown(42, 42)).to eq(0)
      end

      it "ignores nil user id" do
        previous_uid = file.stat.uid

        file.chown(nil, 42)
        expect(file.stat.uid).to eq(previous_uid)
      end

      it "ignores nil group id" do
        previous_gid = file.stat.gid

        file.chown(42, nil)
        expect(file.stat.gid).to eq(previous_gid)
      end

      it "ignores -1 user id" do
        previous_uid = file.stat.uid

        file.chown(-1, 42)
        expect(file.stat.uid).to eq(previous_uid)
      end

      it "ignores -1 group id" do
        previous_gid = file.stat.gid

        file.chown(42, -1)
        expect(file.stat.gid).to eq(previous_gid)
      end

      context "when the named entry is a symlink" do
        let(:symlink) { File.new('/test-link') }

        it "changes the owner on the last target of the link chain" do
          symlink.chown(42, nil)
          expect(file.stat.uid).to be(42)
        end

        it "changes the group on the last target of the link chain" do
          symlink.chown(nil, 42)
          expect(file.stat.gid).to be(42)
        end

        it "does not change the owner of the symlink" do
          symlink.chown(42, nil)
          expect(symlink.lstat.uid).not_to be(42)
        end

        it "does not change the group of the symlink" do
          symlink.chown(nil, 42)
          expect(symlink.lstat.gid).not_to be(42)
        end
      end
    end

    describe '#lstat' do
      it "returns the File::Stat object of the file" do
        expect(file.lstat).to be_a(File::Stat)
      end

      it "does not follow the last symbolic link" do
        file = File.new('/test-link')
        expect(file.lstat).to be_symlink
      end

      context "when the named file is a symlink" do
        context "and its target does not exist" do
          it "ignores errors" do
            file = File.new('/no-link')
            expect { file.lstat }.not_to raise_error(Errno::ENOENT)
          end
        end
      end
    end

    describe '#chmod' do
      it "changes permission bits on the file" do
        file.chmod(0777)
        expect(file.stat.mode).to eq(0100777)
      end

      it "returns zero" do
        expect(file.chmod(0777)).to eq(0)
      end
    end

    describe ".file?" do
      context "when the named file exists" do
        context "and it is a regular file" do
          it "returns true" do
            expect(File.file?('/test-file')).to be_true
          end
        end

        context "and it is not a regular file" do
          it "returns false" do
            expect(File.file?('/test-dir')).to be_false
          end
        end
      end

      context "when the named file does not exist" do
        it "returns false" do
          expect(File.file?('/no-file')).to be_false
        end
      end
    end

    describe ".symlink?" do
      context "when the named file is a symlink" do
        it "returns true" do
          expect(File.symlink?('/test-link')).to be_true
        end
      end

      context "when the named file is not a symlink" do
        it "returns false" do
          expect(File.symlink?('/test-file')).to be_false
        end
      end
    end

    describe ".readlink" do
      it "returns the name of the file referenced by the given link" do
        expect(File.readlink('/test-link')).to eq('/test-file')
      end
    end
  end
end
