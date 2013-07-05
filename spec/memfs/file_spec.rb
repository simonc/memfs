require 'spec_helper'

module MemFs
  describe File do
    subject { MemFs::File }

    let(:file) { File.new('/test-file') }
    let(:random_string) { ('a'..'z').to_a.sample(10).join }

    before :each do
      fs.mkdir '/test-dir'
      fs.touch '/test-file', '/test-file2'
      File.symlink '/test-file', '/test-link'
      File.symlink '/no-file', '/no-link'
    end

    describe '.atime' do
      it "returns the last access time for the named file as a Time object" do
        expect(File.atime('/test-file')).to be_a(Time)
      end

      it "raises an error if the entry does not exist" do
        expect { File.atime('/no-file') }.to raise_error(Errno::ENOENT)
      end

      context "when the entry is a symlink" do
        let(:time) { Time.now - 500000 }

        it "returns the last access time of the last target of the link chain" do
          fs.find!('/test-file').atime = time
          File.symlink('/test-link', '/test-link2')
          expect(File.atime('/test-link2')).to eq(time)
        end
      end
    end

    describe ".basename" do
      it "returns the last component of the filename given in +file_name+" do
        expect(File.basename('/path/to/file.txt')).to eq('file.txt')
      end

      context "when +suffix+ is given" do
        context "when it is present at the end of +file_name+" do
          it "removes the +suffix+ from the filename basename" do
            expect(File.basename('/path/to/file.txt', '.txt')).to eq('file')
          end
        end
      end
    end

    describe '.chmod' do
      it "changes permission bits on the named file" do
        File.chmod(0777, '/test-file')
        expect(File.stat('/test-file').mode).to eq(0100777)
      end

      it "changes permission bits on the named files (in list)" do
        File.chmod(0777, '/test-file', '/test-file2')
        expect(File.stat('/test-file2').mode).to eq(0100777)
      end
    end

    describe ".chown" do
      it "changes the owner of the named file to the given numeric owner id" do
        File.chown(42, nil, '/test-file')
        expect(File.stat('/test-file').uid).to eq(42)
      end

      it "changes owner on the named files (in list)" do
        File.chown(42, nil, '/test-file', '/test-file2')
        expect(File.stat('/test-file2').uid).to eq(42)
      end

      it "changes the group of the named file to the given numeric group id" do
        File.chown(nil, 42, '/test-file')
        expect(File.stat('/test-file').gid).to eq(42)
      end

      it "returns the number of files" do
        expect(File.chown(42, 42, '/test-file', '/test-file2')).to eq(2)
      end

      it "ignores nil user id" do
        previous_uid = File.stat('/test-file').uid

        File.chown(nil, 42, '/test-file')
        expect(File.stat('/test-file').uid).to eq(previous_uid)
      end

      it "ignores nil group id" do
        previous_gid = File.stat('/test-file').gid

        File.chown(42, nil, '/test-file')
        expect(File.stat('/test-file').gid).to eq(previous_gid)
      end

      it "ignores -1 user id" do
        previous_uid = File.stat('/test-file').uid

        File.chown(-1, 42, '/test-file')
        expect(File.stat('/test-file').uid).to eq(previous_uid)
      end

      it "ignores -1 group id" do
        previous_gid = File.stat('/test-file').gid

        File.chown(42, -1, '/test-file')
        expect(File.stat('/test-file').gid).to eq(previous_gid)
      end

      context "when the named entry is a symlink" do
        it "changes the owner on the last target of the link chain" do
          File.chown(42, nil, '/test-link')
          expect(File.stat('/test-file').uid).to eq(42)
        end

        it "changes the group on the last target of the link chain" do
          File.chown(nil, 42, '/test-link')
          expect(File.stat('/test-file').gid).to eq(42)
        end

        it "does not change the owner of the symlink" do
          File.chown(42, nil, '/test-link')
          expect(File.lstat('/test-link').uid).not_to eq(42)
        end

        it "does not change the group of the symlink" do
          File.chown(nil, 42, '/test-link')
          expect(File.lstat('/test-link').gid).not_to eq(42)
        end
      end
    end

    describe ".delete" do
      it_behaves_like 'aliased method', :delete, :unlink
    end

    describe '.directory?' do
      context "when the named entry is a directory" do
        it "returns true" do
          expect(File.directory?('/test-dir')).to be_true
        end
      end

      context "when the named entry is not a directory" do
        it "returns false" do
          expect(File.directory?('/test-file')).to be_false
        end
      end
    end

    describe ".dirname" do
      it "returns all components of the filename given in +file_name+ except the last one" do
        expect(File.dirname('/path/to/some/file.txt')).to eq('/path/to/some')
      end

      it "returns / if file_name is /" do
        expect(File.dirname('/')).to eq('/')
      end
    end

    describe ".exists?" do
      it "returns true if the file exists" do
        expect(File.exists?('/test-file')).to be_true
      end

      it "returns false if the file does not exist" do
        expect(File.exists?('/no-file')).to be_false
      end
    end

    describe ".exist?" do
      it_behaves_like 'aliased method', :exist?, :exists?
    end

    describe ".expand_path" do
      it "converts a pathname to an absolute pathname" do
        fs.chdir('/')
        expect(File.expand_path('test-file')).to eq("/test-file")
      end

      it "references path from the current working directory" do
        fs.chdir('/test-dir')
        expect(File.expand_path('test-file')).to eq("/test-dir/test-file")
      end

      context "when +dir_string+ is provided" do
        it "uses +dir_string+ as the stating point" do
          expect(File.expand_path('test-file', '/test')).to eq("/test/test-file")
        end
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
          expect(File.identical?('/test-file', '/test-file')).to be_true
        end
      end

      context "when two paths do not represent the same file" do
        it "returns false" do
          expect(File.identical?('/test-file', '/test-file2')).to be_false
        end
      end

      context "when one of the paths does not exist" do
        it "returns false" do
          expect(File.identical?('/test-file', '/no-file')).to be_false
        end
      end

      context "when a path is a symlink" do
        context "and the linked file is the same as the other path" do
          it "returns true" do
            expect(File.identical?('/test-file', '/test-file-link')).to be_true
          end
        end

        context "and the linked file is different from the other path" do
          it "returns false" do
            expect(File.identical?('/test-file2', '/test-file-link')).to be_false
          end
        end
      end

      context "when the two paths are symlinks" do
        context "and both links point to the same file" do
          it "returns true" do
            expect(File.identical?('/test-file-link', '/test-file-link2')).to be_true
          end
        end

        context "and both links do not point to the same file" do
          it "returns false" do
            expect(File.identical?('/test-file-link', '/test-file2-link')).to be_false
          end
        end
      end
    end

    describe ".join" do
      it "Returns a new string formed by joining the strings using File::SEPARATOR" do
        expect(File.join('a', 'b', 'c')).to eq('a/b/c')
      end
    end

    describe ".lchmod" do
      context "when the named file is a regular file" do
        it "acts like chmod" do
          File.lchmod(0777, '/test-file')
          expect(File.stat('/test-file').mode).to eq(0100777)
        end
      end

      context "when the named file is a symlink" do
        it "changes permission bits on the symlink" do
          File.lchmod(0777, '/test-link')
          expect(File.lstat('/test-link').mode).to eq(0100777)
        end

        it "does not change permission bits on the link's target" do
          File.lchmod(0777, '/test-link')
          expect(File.stat('/test-file').mode).to eq(0100644)
        end
      end
    end

    describe ".link" do
      before :each do
        File.open('/test-file', 'w') { |f| f.puts 'test' }
      end

      it "creates a new name for an existing file using a hard link" do
        File.link('/test-file', '/new-file')
        expect(File.read('/new-file')).to eq(File.read('/test-file'))
      end

      it "returns zero" do
        expect(File.link('/test-file', '/new-file')).to eq(0)
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

    describe '.lstat' do
      it "returns a File::Stat object for the named file" do
        expect(File.lstat('/test-file')).to be_a(File::Stat)
      end

      context "when the named file does not exist" do
        it "raises an exception" do
          expect { File.lstat('/no-file') }.to raise_error(Errno::ENOENT)
        end
      end

      context "when the named file is a symlink" do
        it "does not follow the last symbolic link" do
          expect(File.lstat('/test-link').symlink?).to be_true
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

    describe '.new' do
      context "when the mode is provided" do
        context "and it is an integer" do
          it "sets the mode to the integer value" do
            file = File.new('/test-file', File::RDWR)
            expect(file.opening_mode).to eq(File::RDWR)
          end
        end

        context "and it is a string" do
          it "sets the mode to the integer value" do
            file = File.new('/test-file', 'r+')
            expect(file.opening_mode).to eq(File::RDWR)
          end
        end

        context "and it specifies that the file must be created" do
          context "and the file already exists" do
            it "changes the mtime of the file" do
              fs.should_receive(:touch).with('/test-file')
              File.new('/test-file', 'w')
            end
          end
        end
      end

      context "when no argument is given" do
        it "raises an exception" do
          expect { File.new }.to raise_error(ArgumentError)
        end
      end

      context "when too many arguments are given" do
        it "raises an exception" do
          expect { File.new(1,2,3,4) }.to raise_error(ArgumentError)
        end
      end
    end

    describe '.path' do
      context "when the path is a string" do
        let(:path) { '/some/path' }

        it "returns the string representation of the path" do
          expect(File.path(path)).to eq('/some/path')
        end
      end

      context "when the path is a Pathname" do
        let(:path) { Pathname.new('/some/path') }

        it "returns the string representation of the path" do
          expect(File.path(path)).to eq('/some/path')
        end
      end
    end

    describe ".read" do
      before :each do
        File.open('/test-file', 'w') { |f| f.puts "test" }
      end

      it "reads the content of the given file" do
        expect(File.read('/test-file')).to eq("test\n")
      end

      context "when +lenght+ is provided" do
        it "reads only +length+ characters" do
          expect(File.read('/test-file', 2)).to eq('te')
        end

        context "when +length+ is bigger than the file size" do
          it "reads until the end of the file" do
            expect(File.read('/test-file', 1000)).to eq("test\n")
          end
        end
      end

      context "when +offset+ is provided" do
        it "starts reading from the offset" do
          expect(File.read('/test-file', 2, 1)).to eq('es')
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

    describe ".readlink" do
      it "returns the name of the file referenced by the given link" do
        expect(File.readlink('/test-link')).to eq('/test-file')
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

    describe ".size" do
      it "returns the size of the file" do
        File.open('/test-file', 'w') { |f| f.puts random_string }
        expect(File.size('/test-file')).to eq(random_string.size + 1)
      end
    end

    describe '.stat' do
      it "returns a File::Stat object for the named file" do
        expect(File.stat('/test-file')).to be_a(File::Stat)
      end

      it "follows the last symbolic link" do
        expect(File.stat('/test-link').symlink?).to be_false
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
        expect(File.stat('/test-file')).not_to be(stat)
      end
    end

    describe '.symlink' do
      it "creates a symbolic link named new_name" do
        expect(File.symlink?('/test-link')).to be_true
      end

      it "creates a symbolic link that points to an entry named old_name" do
        expect(fs.find!('/test-link').target).to eq('/test-file')
      end

      context "when the target does not exist" do
        it "creates a symbolic link" do
          expect(File.symlink?('/no-link')).to be_true
        end
      end

      it "returns 0" do
        expect(File.symlink('/test-file', '/new-link')).to eq(0)
      end
    end

    describe '.symlink?' do
      context "when the named entry is a symlink" do
        it "returns true" do
          expect(File.symlink?('/test-link')).to be_true
        end
      end

      context "when the named entry is not a symlink" do
        it "returns false" do
          expect(File.symlink?('/test-file')).to be_false
        end
      end

      context "when the named entry does not exist" do
        it "returns false" do
          expect(File.symlink?('/no-file')).to be_false
        end
      end
    end

    describe '.umask' do
      it "returns the current umask value for this process" do
        expect(File.umask).to eq(0022)
      end

      context "when the optional argument is given" do
        it "sets the umask to that value" do
          File.umask 0777
          expect(File.umask).to eq(0777)
        end

        it "return the previous value" do
          expect(File.umask(0777)).to eq(0022)
        end
      end
    end

    describe ".unlink" do
      it "deletes the named file" do
        File.unlink('/test-file')
        expect(File.exists?('/test-file')).to be_false
      end

      it "returns the number of names passed as arguments" do
        expect(File.unlink('/test-file', '/test-file2')).to eq(2)
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

    describe '.utime' do
      let(:time) { Time.now - 500000 }

      it "sets the access time of each named file to the first argument" do
        File.utime(time, time, '/test-file')
        expect(File.atime('/test-file')).to eq(time)
      end

      it "sets the modification time of each named file to the second argument" do
        File.utime(time, time, '/test-file')
        expect(File.mtime('/test-file')).to eq(time)
      end

      it "returns the number of file names in the argument list" do
        expect(File.utime(time, time, '/test-file', '/test-file2')).to eq(2)
      end

      it "raises en error if the entry does not exist" do
        expect {
          File.utime(time, time, '/no-file')
        }.to raise_error(Errno::ENOENT)
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

    describe "#close" do
      it "closes the file stream" do
        file = File.open('/test-file')
        file.close
        expect(file).to be_closed
      end
    end

    describe "#closed?" do
      it "returns true when the file is closed" do
        file = File.open('/test-file')
        file.close
        expect(file.closed?).to be_true
      end

      it "returns false when the file is open" do
        file = File.open('/test-file')
        expect(file.closed?).to be_false
        file.close
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

    describe "#path" do
      it "returns the path of the file" do
        file = File.new('/test-file')
        expect(file.path).to eq('/test-file')
      end
    end

    describe "#pos" do
      before :each do
        File.open('/test-file', 'w') { |f| f.puts 'test' }
      end

      it "returns zero when the file was just opened" do
        expect(file.pos).to be_zero
      end

      it "returns the reading offset when some of the file has been read" do
        file.read(2)
        expect(file.pos).to eq(2)
      end
    end

    describe "#puts" do
      it "appends content to the file" do
        file = File.new('/test-file', 'w')
        file.puts "test"
        file.close
        expect(file.content.to_s).to eq("test\n")
      end

      it "does not override the file's content" do
        file = File.new('/test-file', 'w')
        file.puts "test"
        file.puts "test"
        file.close
        expect(file.content.to_s).to eq("test\ntest\n")
      end

      it "raises an exception if the file is not writable" do
        file = File.new('/test-file')
        expect { file.puts "test" }.to raise_error(IOError)
      end
    end

    describe "#read" do
      before :each do
        File.open('/test-file', 'w') { |f| f.puts random_string }
      end

      context "when no length is given" do
        it "returns the content of the named file" do
          expect(file.read).to eq(random_string + "\n")
        end

        it "returns an empty string if called a second time" do
          file.read
          expect(file.read).to be_empty
        end
      end

      context "when a length is given" do
        it "returns a string of the given length" do
          expect(file.read(2)).to eq(random_string[0, 2])
        end

        it "returns nil when there is nothing more to read" do
          file.read(1000)
          expect(file.read(1000)).to be_nil
        end
      end

      context "when a buffer is given" do
        it "fills the buffer with the read content" do
          buffer = String.new
          file.read(2, buffer)
          expect(buffer).to eq(random_string[0, 2])
        end
      end
    end

    describe "#seek" do
      before :each do
        File.open('/test-file', 'w') { |f| f.puts 'test' }
      end

      it "returns zero" do
        expect(file.seek(1)).to eq(0)
      end

      context "when +whence+ is not provided" do
        it "seeks to the absolute location given by +amount+" do
          file.seek(3)
          expect(file.pos).to eq(3)
        end
      end

      context "when +whence+ is IO::SEEK_CUR" do
        it "seeks to +amount+ plus current position" do
          file.read(1)
          file.seek(1, IO::SEEK_CUR)
          expect(file.pos).to eq(2)
        end
      end

      context "when +whence+ is IO::SEEK_END" do
        it "seeks to +amount+ plus end of stream" do
          file.seek(-1, IO::SEEK_END)
          expect(file.pos).to eq(4)
        end
      end

      context "when +whence+ is IO::SEEK_SET" do
        it "seeks to the absolute location given by +amount+" do
          file.seek(3, IO::SEEK_SET)
          expect(file.pos).to eq(3)
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

    describe "#size" do
      it "returns the size of the file" do
        File.open('/test-file', 'w') { |f| f.puts random_string }
        expect(File.new('/test-file').size).to eq(random_string.size + 1)
      end
    end

    describe "#stat" do
      it "returns the +Stat+ object of the file" do
        file = File.new('/test-file')
        file.stat == File.stat('/test-file')
      end
    end

    describe "#write" do
      it "writes the given string to file" do
        File.open('/test-file', 'w') { |f| f.write "test" }
        expect(File.read('/test-file')).to eq("test")
      end

      it "returns the number of bytes written" do
        file = File.open('/test-file', 'w')
        expect(file.write('test')).to eq(4)
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
          expect(File.read('/test-file')).to eq('42')
        end
      end
    end
  end
end
