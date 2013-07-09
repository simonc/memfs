require 'spec_helper'

module MemFs
  describe File do
    subject { MemFs::File }

    let(:file) { subject.new('/test-file') }
    let(:random_string) { ('a'..'z').to_a.sample(10).join }

    before :each do
      fs.mkdir '/test-dir'
      fs.touch '/test-file', '/test-file2'
      subject.symlink '/test-file', '/test-link'
      subject.symlink '/no-file', '/no-link'
    end

    describe '.atime' do
      it "returns the last access time for the named file as a Time object" do
        expect(subject.atime('/test-file')).to be_a(Time)
      end

      it "raises an error if the entry does not exist" do
        expect { subject.atime('/no-file') }.to raise_error(Errno::ENOENT)
      end

      context "when the entry is a symlink" do
        let(:time) { Time.now - 500000 }

        it "returns the last access time of the last target of the link chain" do
          fs.find!('/test-file').atime = time
          subject.symlink('/test-link', '/test-link2')
          expect(subject.atime('/test-link2')).to eq(time)
        end
      end
    end

    describe ".basename" do
      it "returns the last component of the filename given in +file_name+" do
        expect(subject.basename('/path/to/file.txt')).to eq('file.txt')
      end

      context "when +suffix+ is given" do
        context "when it is present at the end of +file_name+" do
          it "removes the +suffix+ from the filename basename" do
            expect(subject.basename('/path/to/file.txt', '.txt')).to eq('file')
          end
        end
      end
    end

    describe '.chmod' do
      it "changes permission bits on the named file" do
        subject.chmod(0777, '/test-file')
        expect(subject.stat('/test-file').mode).to eq(0100777)
      end

      it "changes permission bits on the named files (in list)" do
        subject.chmod(0777, '/test-file', '/test-file2')
        expect(subject.stat('/test-file2').mode).to eq(0100777)
      end
    end

    describe ".chown" do
      it "changes the owner of the named file to the given numeric owner id" do
        subject.chown(42, nil, '/test-file')
        expect(subject.stat('/test-file').uid).to eq(42)
      end

      it "changes owner on the named files (in list)" do
        subject.chown(42, nil, '/test-file', '/test-file2')
        expect(subject.stat('/test-file2').uid).to eq(42)
      end

      it "changes the group of the named file to the given numeric group id" do
        subject.chown(nil, 42, '/test-file')
        expect(subject.stat('/test-file').gid).to eq(42)
      end

      it "returns the number of files" do
        expect(subject.chown(42, 42, '/test-file', '/test-file2')).to eq(2)
      end

      it "ignores nil user id" do
        previous_uid = subject.stat('/test-file').uid

        subject.chown(nil, 42, '/test-file')
        expect(subject.stat('/test-file').uid).to eq(previous_uid)
      end

      it "ignores nil group id" do
        previous_gid = subject.stat('/test-file').gid

        subject.chown(42, nil, '/test-file')
        expect(subject.stat('/test-file').gid).to eq(previous_gid)
      end

      it "ignores -1 user id" do
        previous_uid = subject.stat('/test-file').uid

        subject.chown(-1, 42, '/test-file')
        expect(subject.stat('/test-file').uid).to eq(previous_uid)
      end

      it "ignores -1 group id" do
        previous_gid = subject.stat('/test-file').gid

        subject.chown(42, -1, '/test-file')
        expect(subject.stat('/test-file').gid).to eq(previous_gid)
      end

      context "when the named entry is a symlink" do
        it "changes the owner on the last target of the link chain" do
          subject.chown(42, nil, '/test-link')
          expect(subject.stat('/test-file').uid).to eq(42)
        end

        it "changes the group on the last target of the link chain" do
          subject.chown(nil, 42, '/test-link')
          expect(subject.stat('/test-file').gid).to eq(42)
        end

        it "does not change the owner of the symlink" do
          subject.chown(42, nil, '/test-link')
          expect(subject.lstat('/test-link').uid).not_to eq(42)
        end

        it "does not change the group of the symlink" do
          subject.chown(nil, 42, '/test-link')
          expect(subject.lstat('/test-link').gid).not_to eq(42)
        end
      end
    end

    describe ".delete" do
      it_behaves_like 'aliased method', :delete, :unlink
    end

    describe '.directory?' do
      context "when the named entry is a directory" do
        it "returns true" do
          expect(subject.directory?('/test-dir')).to be_true
        end
      end

      context "when the named entry is not a directory" do
        it "returns false" do
          expect(subject.directory?('/test-file')).to be_false
        end
      end
    end

    describe ".dirname" do
      it "returns all components of the filename given in +file_name+ except the last one" do
        expect(subject.dirname('/path/to/some/file.txt')).to eq('/path/to/some')
      end

      it "returns / if file_name is /" do
        expect(subject.dirname('/')).to eq('/')
      end
    end

    describe ".exists?" do
      it "returns true if the file exists" do
        expect(subject.exists?('/test-file')).to be_true
      end

      it "returns false if the file does not exist" do
        expect(subject.exists?('/no-file')).to be_false
      end
    end

    describe ".exist?" do
      it_behaves_like 'aliased method', :exist?, :exists?
    end

    describe ".expand_path" do
      it "converts a pathname to an absolute pathname" do
        fs.chdir('/')
        expect(subject.expand_path('test-file')).to eq("/test-file")
      end

      it "references path from the current working directory" do
        fs.chdir('/test-dir')
        expect(subject.expand_path('test-file')).to eq("/test-dir/test-file")
      end

      context "when +dir_string+ is provided" do
        it "uses +dir_string+ as the stating point" do
          expect(subject.expand_path('test-file', '/test')).to eq("/test/test-file")
        end
      end
    end

    describe ".file?" do
      context "when the named file exists" do
        context "and it is a regular file" do
          it "returns true" do
            expect(subject.file?('/test-file')).to be_true
          end
        end

        context "and it is not a regular file" do
          it "returns false" do
            expect(subject.file?('/test-dir')).to be_false
          end
        end
      end

      context "when the named file does not exist" do
        it "returns false" do
          expect(subject.file?('/no-file')).to be_false
        end
      end
    end

    describe ".identical?" do
      before :each do
        subject.open('/test-file', 'w') { |f| f.puts 'test' }
        subject.open('/test-file2', 'w') { |f| f.puts 'test' }
        subject.symlink '/test-file', '/test-file-link'
        subject.symlink '/test-file', '/test-file-link2'
        subject.symlink '/test-file2', '/test-file2-link'
      end

      context "when two paths represent the same path" do
        it "returns true" do
          expect(subject.identical?('/test-file', '/test-file')).to be_true
        end
      end

      context "when two paths do not represent the same file" do
        it "returns false" do
          expect(subject.identical?('/test-file', '/test-file2')).to be_false
        end
      end

      context "when one of the paths does not exist" do
        it "returns false" do
          expect(subject.identical?('/test-file', '/no-file')).to be_false
        end
      end

      context "when a path is a symlink" do
        context "and the linked file is the same as the other path" do
          it "returns true" do
            expect(subject.identical?('/test-file', '/test-file-link')).to be_true
          end
        end

        context "and the linked file is different from the other path" do
          it "returns false" do
            expect(subject.identical?('/test-file2', '/test-file-link')).to be_false
          end
        end
      end

      context "when the two paths are symlinks" do
        context "and both links point to the same file" do
          it "returns true" do
            expect(subject.identical?('/test-file-link', '/test-file-link2')).to be_true
          end
        end

        context "and both links do not point to the same file" do
          it "returns false" do
            expect(subject.identical?('/test-file-link', '/test-file2-link')).to be_false
          end
        end
      end
    end

    describe ".join" do
      it "Returns a new string formed by joining the strings using File::SEPARATOR" do
        expect(subject.join('a', 'b', 'c')).to eq('a/b/c')
      end
    end

    describe ".lchmod" do
      context "when the named file is a regular file" do
        it "acts like chmod" do
          subject.lchmod(0777, '/test-file')
          expect(subject.stat('/test-file').mode).to eq(0100777)
        end
      end

      context "when the named file is a symlink" do
        it "changes permission bits on the symlink" do
          subject.lchmod(0777, '/test-link')
          expect(subject.lstat('/test-link').mode).to eq(0100777)
        end

        it "does not change permission bits on the link's target" do
          subject.lchmod(0777, '/test-link')
          expect(subject.stat('/test-file').mode).to eq(0100646)
        end
      end
    end

    describe ".link" do
      before :each do
        subject.open('/test-file', 'w') { |f| f.puts 'test' }
      end

      it "creates a new name for an existing file using a hard link" do
        subject.link('/test-file', '/new-file')
        expect(subject.read('/new-file')).to eq(subject.read('/test-file'))
      end

      it "returns zero" do
        expect(subject.link('/test-file', '/new-file')).to eq(0)
      end

      context "when +old_name+ does not exist" do
        it "raises an exception" do
          expect {
            subject.link('/no-file', '/nowhere')
          }.to raise_error(Errno::ENOENT)
        end
      end

      context "when +new_name+ already exists" do
        it "raises an exception" do
          subject.open('/test-file2', 'w') { |f| f.puts 'test2' }
          expect {
            subject.link('/test-file', '/test-file2')
          }.to raise_error(SystemCallError)
        end
      end
    end

    describe '.lstat' do
      it "returns a File::Stat object for the named file" do
        expect(subject.lstat('/test-file')).to be_a(File::Stat)
      end

      context "when the named file does not exist" do
        it "raises an exception" do
          expect { subject.lstat('/no-file') }.to raise_error(Errno::ENOENT)
        end
      end

      context "when the named file is a symlink" do
        it "does not follow the last symbolic link" do
          expect(subject.lstat('/test-link').symlink?).to be_true
        end

        context "and its target does not exist" do
          it "ignores errors" do
            expect {
              subject.lstat('/no-link')
            }.not_to raise_error(Errno::ENOENT)
          end
        end
      end
    end

    describe '.new' do
      context "when the mode is provided" do
        context "and it is an integer" do
          it "sets the mode to the integer value" do
            file = subject.new('/test-file', File::RDWR)
            expect(file.opening_mode).to eq(File::RDWR)
          end
        end

        context "and it is a string" do
          it "sets the mode to the integer value" do
            file = subject.new('/test-file', 'r+')
            expect(file.opening_mode).to eq(File::RDWR)
          end
        end

        context "and it specifies that the file must be created" do
          context "and the file already exists" do
            it "changes the mtime of the file" do
              fs.should_receive(:touch).with('/test-file')
              subject.new('/test-file', 'w')
            end
          end
        end
      end

      context "when no argument is given" do
        it "raises an exception" do
          expect { subject.new }.to raise_error(ArgumentError)
        end
      end

      context "when too many arguments are given" do
        it "raises an exception" do
          expect { subject.new(1,2,3,4) }.to raise_error(ArgumentError)
        end
      end
    end

    describe '.path' do
      context "when the path is a string" do
        let(:path) { '/some/path' }

        it "returns the string representation of the path" do
          expect(subject.path(path)).to eq('/some/path')
        end
      end

      context "when the path is a Pathname" do
        let(:path) { Pathname.new('/some/path') }

        it "returns the string representation of the path" do
          expect(subject.path(path)).to eq('/some/path')
        end
      end
    end

    describe ".read" do
      before :each do
        subject.open('/test-file', 'w') { |f| f.puts "test" }
      end

      it "reads the content of the given file" do
        expect(subject.read('/test-file')).to eq("test\n")
      end

      context "when +lenght+ is provided" do
        it "reads only +length+ characters" do
          expect(subject.read('/test-file', 2)).to eq('te')
        end

        context "when +length+ is bigger than the file size" do
          it "reads until the end of the file" do
            expect(subject.read('/test-file', 1000)).to eq("test\n")
          end
        end
      end

      context "when +offset+ is provided" do
        it "starts reading from the offset" do
          expect(subject.read('/test-file', 2, 1)).to eq('es')
        end

        it "raises an error if offset is negative" do
          expect {
            subject.read('/test-file', 2, -1)
          }.to raise_error(Errno::EINVAL)
        end
      end

      context "when the last argument is a hash" do
        it "passes the contained options to +open+" do
          subject.should_receive(:open)
              .with('/test-file', File::RDONLY, encoding: 'UTF-8')
              .and_return(file)
          subject.read('/test-file', encoding: 'UTF-8')
        end

        context "when it contains the +open_args+ key" do
          it "takes precedence over the other options" do
            subject.should_receive(:open)
                .with('/test-file', 'r')
                .and_return(file)
            subject.read('/test-file', mode: 'w', open_args: ['r'])
          end
        end
      end
    end

    describe ".readlink" do
      it "returns the name of the file referenced by the given link" do
        expect(subject.readlink('/test-link')).to eq('/test-file')
      end
    end

    describe ".rename" do
      it "renames the given file to the new name" do
        subject.rename('/test-file', '/test-file2')
        expect(subject.exists?('/test-file2')).to be_true
      end

      it "returns zero" do
        expect(subject.rename('/test-file', '/test-file2')).to eq(0)
      end
    end

    describe ".size" do
      it "returns the size of the file" do
        subject.open('/test-file', 'w') { |f| f.puts random_string }
        expect(subject.size('/test-file')).to eq(random_string.size + 1)
      end
    end

    describe '.stat' do
      it "returns a File::Stat object for the named file" do
        expect(subject.stat('/test-file')).to be_a(File::Stat)
      end

      it "follows the last symbolic link" do
        expect(subject.stat('/test-link').symlink?).to be_false
      end

      context "when the named file does not exist" do
        it "raises an exception" do
          expect { subject.stat('/no-file') }.to raise_error(Errno::ENOENT)
        end
      end

      context "when the named file is a symlink" do
        context "and its target does not exist" do
          it "raises an exception" do
            expect { subject.stat('/no-link') }.to raise_error(Errno::ENOENT)
          end
        end
      end

      it "always returns a new object" do
        stat = subject.stat('/test-file')
        expect(subject.stat('/test-file')).not_to be(stat)
      end
    end

    describe '.symlink' do
      it "creates a symbolic link named new_name" do
        expect(subject.symlink?('/test-link')).to be_true
      end

      it "creates a symbolic link that points to an entry named old_name" do
        expect(fs.find!('/test-link').target).to eq('/test-file')
      end

      context "when the target does not exist" do
        it "creates a symbolic link" do
          expect(subject.symlink?('/no-link')).to be_true
        end
      end

      it "returns 0" do
        expect(subject.symlink('/test-file', '/new-link')).to eq(0)
      end
    end

    describe '.symlink?' do
      context "when the named entry is a symlink" do
        it "returns true" do
          expect(subject.symlink?('/test-link')).to be_true
        end
      end

      context "when the named entry is not a symlink" do
        it "returns false" do
          expect(subject.symlink?('/test-file')).to be_false
        end
      end

      context "when the named entry does not exist" do
        it "returns false" do
          expect(subject.symlink?('/no-file')).to be_false
        end
      end
    end

    describe '.umask' do
      before :each do
        subject.umask(0022)
      end

      it "returns the current umask value for this process" do
        expect(subject.umask).to eq(0022)
      end

      context "when the optional argument is given" do
        it "sets the umask to that value" do
          subject.umask 0777
          expect(subject.umask).to eq(0777)
        end

        it "return the previous value" do
          expect(subject.umask(0777)).to eq(0022)
        end
      end
    end

    describe ".unlink" do
      it "deletes the named file" do
        subject.unlink('/test-file')
        expect(subject.exists?('/test-file')).to be_false
      end

      it "returns the number of names passed as arguments" do
        expect(subject.unlink('/test-file', '/test-file2')).to eq(2)
      end

      context "when multiple file names are given" do
        it "deletes the named files" do
          subject.unlink('/test-file', '/test-file2')
          expect(subject.exists?('/test-file2')).to be_false
        end
      end

      context "when the entry is a directory" do
        it "raises an exception" do
          expect { subject.unlink('/test-dir') }.to raise_error(Errno::EPERM)
        end
      end
    end

    describe '.utime' do
      let(:time) { Time.now - 500000 }

      it "sets the access time of each named file to the first argument" do
        subject.utime(time, time, '/test-file')
        expect(subject.atime('/test-file')).to eq(time)
      end

      it "sets the modification time of each named file to the second argument" do
        subject.utime(time, time, '/test-file')
        expect(subject.mtime('/test-file')).to eq(time)
      end

      it "returns the number of file names in the argument list" do
        expect(subject.utime(time, time, '/test-file', '/test-file2')).to eq(2)
      end

      it "raises en error if the entry does not exist" do
        expect {
          subject.utime(time, time, '/no-file')
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
        let(:symlink) { subject.new('/test-link') }

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
        file = subject.open('/test-file')
        file.close
        expect(file).to be_closed
      end
    end

    describe "#closed?" do
      it "returns true when the file is closed" do
        file = subject.open('/test-file')
        file.close
        expect(file.closed?).to be_true
      end

      it "returns false when the file is open" do
        file = subject.open('/test-file')
        expect(file.closed?).to be_false
        file.close
      end
    end

    describe '#lstat' do
      it "returns the File::Stat object of the file" do
        expect(file.lstat).to be_a(File::Stat)
      end

      it "does not follow the last symbolic link" do
        file = subject.new('/test-link')
        expect(file.lstat).to be_symlink
      end

      context "when the named file is a symlink" do
        context "and its target does not exist" do
          it "ignores errors" do
            file = subject.new('/no-link')
            expect { file.lstat }.not_to raise_error(Errno::ENOENT)
          end
        end
      end
    end

    describe "#path" do
      it "returns the path of the file" do
        file = subject.new('/test-file')
        expect(file.path).to eq('/test-file')
      end
    end

    describe "#pos" do
      before :each do
        subject.open('/test-file', 'w') { |f| f.puts 'test' }
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
        file = subject.new('/test-file', 'w')
        file.puts "test"
        file.close
        expect(file.content.to_s).to eq("test\n")
      end

      it "does not override the file's content" do
        file = subject.new('/test-file', 'w')
        file.puts "test"
        file.puts "test"
        file.close
        expect(file.content.to_s).to eq("test\ntest\n")
      end

      it "raises an exception if the file is not writable" do
        file = subject.new('/test-file')
        expect { file.puts "test" }.to raise_error(IOError)
      end
    end

    describe "#read" do
      before :each do
        subject.open('/test-file', 'w') { |f| f.puts random_string }
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
        subject.open('/test-file', 'w') { |f| f.puts 'test' }
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
        subject.open('/test-file', 'w') { |f| f.puts random_string }
        expect(subject.new('/test-file').size).to eq(random_string.size + 1)
      end
    end

    describe "#stat" do
      it "returns the +Stat+ object of the file" do
        file = subject.new('/test-file')
        file.stat == subject.stat('/test-file')
      end
    end

    describe "#write" do
      it "writes the given string to file" do
        subject.open('/test-file', 'w') { |f| f.write "test" }
        expect(subject.read('/test-file')).to eq("test")
      end

      it "returns the number of bytes written" do
        file = subject.open('/test-file', 'w')
        expect(file.write('test')).to eq(4)
        file.close
      end

      context "when the file is not opened for writing" do
        it "raises an exception" do
          file = subject.open('/test-file')
          expect { file.write('test') }.to raise_error(IOError)
          file.close
        end
      end

      context "when the argument is not a string" do
        it "will be converted to a string using to_s" do
          subject.open('/test-file', 'w') { |f| f.write 42 }
          expect(subject.read('/test-file')).to eq('42')
        end
      end
    end
  end
end
