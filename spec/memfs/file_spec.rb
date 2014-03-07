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

    describe '.absolute_path' do
      before :each do
        MemFs::Dir.chdir('/test-dir')
      end

      it "converts a pathname to an absolute pathname" do
        path = subject.absolute_path('./test-file')
        expect(path).to eq('/test-dir/test-file')
      end

      context "when +dir_string+ is given" do
        it "uses it as the starting point" do
          path = subject.absolute_path('./test-file', '/no-dir')
          expect(path).to eq('/no-dir/test-file')
        end
      end

      context "when the given pathname starts with a '~'" do
        it "does not expanded" do
          path = subject.absolute_path('~/test-file')
          expect(path).to eq('/test-dir/~/test-file')
        end
      end
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

    describe ".blockdev?" do
      context "when the name file exists" do
        context "and it is a block device" do
          it "returns true" do
            fs.touch('/block-file')
            file = fs.find('/block-file')
            file.block_device = true
            blockdev = subject.blockdev?('/block-file')
            expect(blockdev).to be_true
          end
        end

        context "and it is not a block device" do
          it "returns false" do
            blockdev = subject.blockdev?('/test-file')
            expect(blockdev).to be_false
          end
        end
      end

      context "when the name file does not exist" do
        it "returns false" do
          blockdev = subject.blockdev?('/no-file')
          expect(blockdev).to be_false
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

    describe ".chardev?" do
      context "when the name file exists" do
        context "and it is a character device" do
          it "returns true" do
            fs.touch('/character-file')
            file = fs.find('/character-file')
            file.character_device = true
            chardev = subject.chardev?('/character-file')
            expect(chardev).to be_true
          end
        end

        context "and it is not a character device" do
          it "returns false" do
            chardev = subject.chardev?('/test-file')
            expect(chardev).to be_false
          end
        end
      end

      context "when the name file does not exist" do
        it "returns false" do
          chardev = subject.chardev?('/no-file')
          expect(chardev).to be_false
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
        expect {
          subject.chown(nil, 42, '/test-file')
        }.to_not change{subject.stat('/test-file').uid}
      end

      it "ignores nil group id" do
        expect {
          subject.chown(42, nil, '/test-file')
        }.to_not change{subject.stat('/test-file').gid}
      end

      it "ignores -1 user id" do
        expect {
          subject.chown(-1, 42, '/test-file')
        }.to_not change{subject.stat('/test-file').uid}
      end

      it "ignores -1 group id" do
        expect {
          subject.chown(42, -1, '/test-file')
        }.to_not change{subject.stat('/test-file').gid}
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

    describe ".ctime" do
      it "returns the change time for the named file as a Time object" do
        expect(subject.ctime('/test-file')).to be_a(Time)
      end

      it "raises an error if the entry does not exist" do
        expect { subject.ctime('/no-file') }.to raise_error(Errno::ENOENT)
      end

      context "when the entry is a symlink" do
        let(:time) { Time.now - 500000 }

        it "returns the last access time of the last target of the link chain" do
          fs.find!('/test-file').ctime = time
          subject.symlink('/test-link', '/test-link2')
          expect(subject.ctime('/test-link2')).to eq(time)
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

    describe ".executable?" do
      let(:access) { 0 }
      let(:gid) { 0 }
      let(:uid) { 0 }

      before :each do
        subject.chmod(access, '/test-file')
        subject.chown(uid, gid, '/test-file')
      end

      context "when the file is not executable by anyone" do
        it "return false" do
          executable = subject.executable?('/test-file')
          expect(executable).to be_false
        end
      end

      context "when the file is user executable" do
        let(:access) { MemFs::Fake::Entry::UEXEC }

        context "and the current user owns the file" do
          before(:each) { subject.chown(uid, 0, '/test-file') }
          let(:uid) { Process.euid }

          it "returns true" do
            executable = subject.executable?('/test-file')
            expect(executable).to be_true
          end
        end
      end

      context "when the file is group executable" do
        let(:access) { MemFs::Fake::Entry::GEXEC }

        context "and the current user is part of the owner group" do
          let(:gid) { Process.egid }

          it "returns true" do
            executable = subject.executable?('/test-file')
            expect(executable).to be_true
          end
        end
      end

      context "when the file is executable by anyone" do
        let(:access) { MemFs::Fake::Entry::OEXEC }

        context "and the user has no specific right on it" do
          it "returns true" do
            executable = subject.executable?('/test-file')
            expect(executable).to be_true
          end
        end
      end

      context "when the file does not exist" do
        it "returns false" do
          executable = subject.executable?('/no-file')
          expect(executable).to be_false
        end
      end
    end

    describe ".executable_real?" do
      let(:access) { 0 }
      let(:gid) { 0 }
      let(:uid) { 0 }

      before :each do
        subject.chmod(access, '/test-file')
        subject.chown(uid, gid, '/test-file')
      end

      context "when the file is not executable by anyone" do
        it "return false" do
          executable = subject.executable_real?('/test-file')
          expect(executable).to be_false
        end
      end

      context "when the file is user executable" do
        let(:access) { MemFs::Fake::Entry::UEXEC }

        context "and the current user owns the file" do
          before(:each) { subject.chown(uid, 0, '/test-file') }
          let(:uid) { Process.uid }

          it "returns true" do
            executable = subject.executable_real?('/test-file')
            expect(executable).to be_true
          end
        end
      end

      context "when the file is group executable" do
        let(:access) { MemFs::Fake::Entry::GEXEC }

        context "and the current user is part of the owner group" do
          let(:gid) { Process.gid }

          it "returns true" do
            executable = subject.executable_real?('/test-file')
            expect(executable).to be_true
          end
        end
      end

      context "when the file is executable by anyone" do
        let(:access) { MemFs::Fake::Entry::OEXEC }

        context "and the user has no specific right on it" do
          it "returns true" do
            executable = subject.executable_real?('/test-file')
            expect(executable).to be_true
          end
        end
      end

      context "when the file does not exist" do
        it "returns false" do
          executable = subject.executable_real?('/no-file')
          expect(executable).to be_false
        end
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

    describe ".extname" do
      it "returns the extension of the given path" do
        expect(subject.extname('test-file.txt')).to eq('.txt')
      end

      context "when the given path starts with a period" do
        context "and the path has no extension" do
          it "returns an empty string" do
            expect(subject.extname('.test-file')).to eq('')
          end
        end

        context "and the path has an extension" do
          it "returns the extension" do
            expect(subject.extname('.test-file.txt')).to eq('.txt')
          end
        end
      end

      context "when the period is the last character in path" do
        it "returns an empty string" do
          expect(subject.extname('test-file.')).to eq('')
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

    describe ".fnmatch" do
      context "when the given path matches against the given pattern" do
        it "returns true" do
          expect(File.fnmatch('c?t', 'cat')).to be_true
        end
      end

      context "when the given path does not match against the given pattern" do
        it "returns false" do
          expect(File.fnmatch('c?t', 'tac')).to be_false
        end
      end
    end

    describe ".fnmatch?" do
      it_behaves_like 'aliased method', :fnmatch?, :fnmatch
    end

    describe ".ftype" do
      context "when the named entry is a regular file" do
        it "returns 'file'" do
          expect(subject.ftype('/test-file')).to eq('file')
        end
      end

      context "when the named entry is a directory" do
        it "returns 'directory'" do
          expect(subject.ftype('/test-dir')).to eq('directory')
        end
      end

      context "when the named entry is a block device" do
        it "returns 'blockSpecial'" do
          fs.touch('/block-file')
          file = fs.find('/block-file')
          file.block_device = true
          expect(subject.ftype('/block-file')).to eq('blockSpecial')
        end
      end

      context "when the named entry is a character device" do
        it "returns 'characterSpecial'" do
          fs.touch('/character-file')
          file = fs.find('/character-file')
          file.character_device = true
          expect(subject.ftype('/character-file')).to eq('characterSpecial')
        end
      end

      context "when the named entry is a symlink" do
        it "returns 'link'" do
          expect(subject.ftype('/test-link')).to eq('link')
        end
      end

      # fifo and socket not handled for now

      context "when the named entry has no specific type" do
        it "returns 'unknown'" do
          root = fs.find('/')
          root.add_entry Fake::Entry.new('test-entry')
          expect(subject.ftype('/test-entry')).to eq('unknown')
        end
      end
    end

    describe ".grpowned?" do
      context "when the named file exists" do
        context "and the effective user group owns of the file" do
          it "returns true" do
            subject.chown(0, Process.egid, '/test-file')
            expect(File.grpowned?('/test-file')).to be_true
          end
        end

        context "and the effective user group does not own of the file" do
          it "returns false" do
            subject.chown(0, 0, '/test-file')
            expect(File.grpowned?('/test-file')).to be_false
          end
        end
      end

      context "when the named file does not exist" do
        it "returns false" do
          expect(File.grpowned?('/no-file')).to be_false
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
          mode = subject.stat('/test-file').mode
          subject.lchmod(0777, '/test-link')
          expect(subject.stat('/test-file').mode).to eq(mode)
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

        context 'and it specifies that the file must be truncated' do
          context 'and the file already exists' do
            it 'truncates its content' do
              subject.open('/test-file', 'w') { |f| f.puts 'hello' }
              file = subject.new('/test-file', 'w')
              file.close
              expect(subject.read('/test-file')).to eq ''
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

    describe ".owned?" do
      context "when the named file exists" do
        context "and the effective user owns of the file" do
          it "returns true" do
            subject.chown(Process.euid, 0, '/test-file')
            expect(File.owned?('/test-file')).to be_true
          end
        end

        context "and the effective user does not own of the file" do
          it "returns false" do
            subject.chown(0, 0, '/test-file')
            expect(File.owned?('/test-file')).to be_false
          end
        end
      end

      context "when the named file does not exist" do
        it "returns false" do
          expect(File.owned?('/no-file')).to be_false
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

    describe ".pipe?" do
      # Pipes are not handled for now

      context "when the named file is not a pipe" do
        it "returns false" do
          pipe = File.pipe?('/test-file')
          expect(pipe).to be_false
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

    describe ".readable?" do
      let(:access) { 0 }
      let(:gid) { 0 }
      let(:uid) { 0 }

      before :each do
        subject.chmod(access, '/test-file')
        subject.chown(uid, gid, '/test-file')
      end

      context "when the file is not readable by anyone" do
        it "return false" do
          readable = subject.readable?('/test-file')
          expect(readable).to be_false
        end
      end

      context "when the file is user readable" do
        let(:access) { MemFs::Fake::Entry::UREAD }

        context "and the current user owns the file" do
          before(:each) { subject.chown(uid, 0, '/test-file') }
          let(:uid) { Process.euid }

          it "returns true" do
            readable = subject.readable?('/test-file')
            expect(readable).to be_true
          end
        end
      end

      context "when the file is group readable" do
        let(:access) { MemFs::Fake::Entry::GREAD }

        context "and the current user is part of the owner group" do
          let(:gid) { Process.egid }

          it "returns true" do
            readable = subject.readable?('/test-file')
            expect(readable).to be_true
          end
        end
      end

      context "when the file is readable by anyone" do
        let(:access) { MemFs::Fake::Entry::OREAD }

        context "and the user has no specific right on it" do
          it "returns true" do
            readable = subject.readable?('/test-file')
            expect(readable).to be_true
          end
        end
      end

      context "when the file does not exist" do
        it "returns false" do
          readable = subject.readable?('/no-file')
          expect(readable).to be_false
        end
      end
    end

    describe ".readable_real?" do
      let(:access) { 0 }
      let(:gid) { 0 }
      let(:uid) { 0 }

      before :each do
        subject.chmod(access, '/test-file')
        subject.chown(uid, gid, '/test-file')
      end

      context "when the file is not readable by anyone" do
        it "return false" do
          readable = subject.readable_real?('/test-file')
          expect(readable).to be_false
        end
      end

      context "when the file is user readable" do
        let(:access) { MemFs::Fake::Entry::UREAD }

        context "and the current user owns the file" do
          before(:each) { subject.chown(uid, 0, '/test-file') }
          let(:uid) { Process.uid }

          it "returns true" do
            readable = subject.readable_real?('/test-file')
            expect(readable).to be_true
          end
        end
      end

      context "when the file is group readable" do
        let(:access) { MemFs::Fake::Entry::GREAD }

        context "and the current user is part of the owner group" do
          let(:gid) { Process.gid }

          it "returns true" do
            readable = subject.readable_real?('/test-file')
            expect(readable).to be_true
          end
        end
      end

      context "when the file is readable by anyone" do
        let(:access) { MemFs::Fake::Entry::OREAD }

        context "and the user has no specific right on it" do
          it "returns true" do
            readable = subject.readable_real?('/test-file')
            expect(readable).to be_true
          end
        end
      end

      context "when the file does not exist" do
        it "returns false" do
          readable = subject.readable_real?('/no-file')
          expect(readable).to be_false
        end
      end
    end

    describe ".readlink" do
      it "returns the name of the file referenced by the given link" do
        expect(subject.readlink('/test-link')).to eq('/test-file')
      end
    end

    describe ".realdirpath" do
      before :each do
        fs.mkdir('/test-dir/sub-dir')
        fs.symlink('/test-dir/sub-dir', '/test-dir/sub-dir-link')
        fs.touch('/test-dir/sub-dir/test-file')
      end

      context "when the path does not contain any symlink or useless dots" do
        it "returns the path itself" do
          path = subject.realdirpath('/test-file')
          expect(path).to eq('/test-file')
        end
      end

      context "when the path contains a symlink" do
        context "and the symlink is a middle part" do
          it "returns the path with the symlink dereferrenced" do
            path = subject.realdirpath('/test-dir/sub-dir-link/test-file')
            expect(path).to eq('/test-dir/sub-dir/test-file')
          end
        end

        context "and the symlink is the last part" do
          it "returns the path with the symlink dereferrenced" do
            path = subject.realdirpath('/test-dir/sub-dir-link')
            expect(path).to eq('/test-dir/sub-dir')
          end
        end
      end

      context "when the path contains useless dots" do
        it "returns the path with the useless dots interpolated" do
          path = subject.realdirpath('/test-dir/../test-dir/./sub-dir/test-file')
          expect(path).to eq('/test-dir/sub-dir/test-file')
        end
      end

      context 'when the given path is relative' do
        context "and +dir_string+ is not provided" do
          it "uses the current working directory has base directory" do
            fs.chdir('/test-dir')
            path = subject.realdirpath('../test-dir/./sub-dir/test-file')
            expect(path).to eq('/test-dir/sub-dir/test-file')
          end
        end

        context "and +dir_string+ is provided" do
          it "uses the given directory has base directory" do
            path = subject.realdirpath('../test-dir/./sub-dir/test-file', '/test-dir')
            expect(path).to eq('/test-dir/sub-dir/test-file')
          end
        end
      end

      context "when the last part of the given path is a symlink" do
        context "and its target does not exist" do
          before :each do
            fs.symlink('/test-dir/sub-dir/test', '/test-dir/sub-dir/test-link')
          end

          it "uses the name of the target in the resulting path" do
            path = subject.realdirpath('/test-dir/sub-dir/test-link')
            expect(path).to eq('/test-dir/sub-dir/test')
          end
        end
      end

      context "when the last part of the given path does not exist" do
        it "uses its name in the resulting path" do
          path = subject.realdirpath('/test-dir/sub-dir/test')
          expect(path).to eq('/test-dir/sub-dir/test')
        end
      end

      context "when a middle part of the given path does not exist" do
        it "raises an exception" do
          expect {
            subject.realdirpath('/no-dir/test-file')
          }.to raise_error
        end
      end
    end

    describe ".realpath" do
      before :each do
        fs.mkdir('/test-dir/sub-dir')
        fs.symlink('/test-dir/sub-dir', '/test-dir/sub-dir-link')
        fs.touch('/test-dir/sub-dir/test-file')
      end

      context "when the path does not contain any symlink or useless dots" do
        it "returns the path itself" do
          path = subject.realpath('/test-file')
          expect(path).to eq('/test-file')
        end
      end

      context "when the path contains a symlink" do
        context "and the symlink is a middle part" do
          it "returns the path with the symlink dereferrenced" do
            path = subject.realpath('/test-dir/sub-dir-link/test-file')
            expect(path).to eq('/test-dir/sub-dir/test-file')
          end
        end

        context "and the symlink is the last part" do
          it "returns the path with the symlink dereferrenced" do
            path = subject.realpath('/test-dir/sub-dir-link')
            expect(path).to eq('/test-dir/sub-dir')
          end
        end
      end

      context "when the path contains useless dots" do
        it "returns the path with the useless dots interpolated" do
          path = subject.realpath('/test-dir/../test-dir/./sub-dir/test-file')
          expect(path).to eq('/test-dir/sub-dir/test-file')
        end
      end

      context 'when the given path is relative' do
        context "and +dir_string+ is not provided" do
          it "uses the current working directory has base directory" do
            fs.chdir('/test-dir')
            path = subject.realpath('../test-dir/./sub-dir/test-file')
            expect(path).to eq('/test-dir/sub-dir/test-file')
          end
        end

        context "and +dir_string+ is provided" do
          it "uses the given directory has base directory" do
            path = subject.realpath('../test-dir/./sub-dir/test-file', '/test-dir')
            expect(path).to eq('/test-dir/sub-dir/test-file')
          end
        end
      end

      context "when a part of the given path does not exist" do
        it "raises an exception" do
          expect {
            subject.realpath('/no-dir/test-file')
          }.to raise_error
        end
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

    describe ".setgid?" do
      context "when the named file exists" do
        context "and the named file has the setgid bit set" do
          it "returns true" do
            fs.chmod(02000, '/test-file')
            expect(File.setgid?('/test-file')).to be_true
          end
        end

        context "and the named file does not have the setgid bit set" do
          it "returns false" do
            expect(File.setgid?('/test-file')).not_to be_true
          end
        end
      end

      context "when the named file does not exist" do
        it "returns false" do
          expect(File.setgid?('/no-file')).to be_false
        end
      end
    end

    describe ".setuid?" do
      context "when the named file exists" do
        context "and the named file has the setuid bit set" do
          it "returns true" do
            fs.chmod(04000, '/test-file')
            expect(File.setuid?('/test-file')).to be_true
          end
        end

        context "and the named file does not have the setuid bit set" do
          it "returns false" do
            expect(File.setuid?('/test-file')).not_to be_true
          end
        end
      end

      context "when the named file does not exist" do
        it "returns false" do
          expect(File.setuid?('/no-file')).to be_false
        end
      end
    end

    describe ".size" do
      it "returns the size of the file" do
        subject.open('/test-file', 'w') { |f| f.puts random_string }
        expect(subject.size('/test-file')).to eq(random_string.size + 1)
      end
    end

    describe ".size?" do
      context "when the named file exists" do
        context "and it is empty" do
          it "returns false" do
            expect(File.size?('/empty-file')).to be_false
          end
        end

        context "and it is not empty" do
          it "returns the size of the file" do
            File.open('/content-file', 'w') { |f| f.write 'test' }
            expect(File.size?('/content-file')).to eq(4)
          end
        end
      end

      context "when the named file does not exist" do
        it "returns false" do
          expect(File.size?('/no-file')).to be_false
        end
      end
    end

    describe ".socket?" do
      # Sockets are not handled for now

      context "when the named file is not a socket" do
        it "returns false" do
          socket = File.socket?('/test-file')
          expect(socket).to be_false
        end
      end
    end

    describe '.split' do
      it "splits the given string into a directory and a file component" do
        result = subject.split('/path/to/some-file')
        expect(result).to eq(['/path/to', 'some-file'])
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

    describe ".sticky?" do
      context "when the named file exists" do
        it "returns true if the named file has the sticky bit set" do
          fs.touch('/test-file')
          fs.chmod(01777, '/test-file')
          expect(File.sticky?('/test-file')).to be_true
        end

        it "returns false if the named file hasn't' the sticky bit set" do
          fs.touch('/test-file')
          expect(File.sticky?('/test-file')).not_to be_true
        end
      end

      context "when the named file does not exist" do
        it "returns false" do
          expect(File.sticky?('/no-file')).to be_false
        end
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

    describe '.truncate' do
      before :each do
        subject.open('/test-file', 'w') { |f| f.write 'x' * 50 }
      end

      it "truncates the named file to the given size" do
        subject.truncate('/test-file', 5)
        expect(subject.size('/test-file')).to eq(5)
      end

      it "returns zero" do
        return_value = subject.truncate('/test-file', 5)
        expect(return_value).to eq(0)
      end

      context "when the named file does not exist" do
        it "raises an exception" do
          expect { subject.truncate('/no-file', 5) }.to raise_error
        end
      end

      context "when the given size is negative" do
        it "it raises an exception" do
          expect { subject.truncate('/test-file', -1) }.to raise_error
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

    describe '.world_readable?' do
      before :each do
        subject.chmod(access, '/test-file')
      end

      context 'when file_name is readable by others' do
        let(:access) { MemFs::Fake::Entry::OREAD }

        it 'returns an integer representing the file permission bits' do
          readable = subject.world_readable?('/test-file')
          expect(readable).to eq(MemFs::Fake::Entry::OREAD)
        end
      end

      context 'when file_name is not readable by others' do
        let(:access) { MemFs::Fake::Entry::UREAD }

        it 'returns nil' do
          readable = subject.world_readable?('/test-file')
          expect(readable).to be_nil
        end
      end
    end

    describe '.world_writable?' do
      before :each do
        subject.chmod(access, '/test-file')
      end

      context 'when file_name is writable by others' do
        let(:access) { MemFs::Fake::Entry::OWRITE }

        it 'returns an integer representing the file permission bits' do
          writable = subject.world_writable?('/test-file')
          expect(writable).to eq(MemFs::Fake::Entry::OWRITE)
        end
      end

      context 'when file_name is not writable by others' do
        let(:access) { MemFs::Fake::Entry::UWRITE }

        it 'returns nil' do
          writable = subject.world_writable?('/test-file')
          expect(writable).to be_nil
        end
      end
    end

    describe ".writable?" do
      let(:access) { 0 }
      let(:gid) { 0 }
      let(:uid) { 0 }

      before :each do
        subject.chmod(access, '/test-file')
        subject.chown(uid, gid, '/test-file')
      end

      context "when the file is not writable by anyone" do
        it "return false" do
          writable = subject.writable?('/test-file')
          expect(writable).to be_false
        end
      end

      context "when the file is user writable" do
        let(:access) { MemFs::Fake::Entry::UWRITE }

        context "and the current user owns the file" do
          before(:each) { subject.chown(uid, 0, '/test-file') }
          let(:uid) { Process.euid }

          it "returns true" do
            writable = subject.writable?('/test-file')
            expect(writable).to be_true
          end
        end
      end

      context "when the file is group writable" do
        let(:access) { MemFs::Fake::Entry::GWRITE }

        context "and the current user is part of the owner group" do
          let(:gid) { Process.egid }

          it "returns true" do
            writable = subject.writable?('/test-file')
            expect(writable).to be_true
          end
        end
      end

      context "when the file is writable by anyone" do
        let(:access) { MemFs::Fake::Entry::OWRITE }

        context "and the user has no specific right on it" do
          it "returns true" do
            writable = subject.writable?('/test-file')
            expect(writable).to be_true
          end
        end
      end

      context "when the file does not exist" do
        it "returns false" do
          writable = subject.writable?('/no-file')
          expect(writable).to be_false
        end
      end
    end

    describe ".writable_real?" do
      let(:access) { 0 }
      let(:gid) { 0 }
      let(:uid) { 0 }

      before :each do
        subject.chmod(access, '/test-file')
        subject.chown(uid, gid, '/test-file')
      end

      context "when the file is not writable by anyone" do
        it "return false" do
          writable = subject.writable_real?('/test-file')
          expect(writable).to be_false
        end
      end

      context "when the file is user writable" do
        let(:access) { MemFs::Fake::Entry::UWRITE }

        context "and the current user owns the file" do
          before(:each) { subject.chown(uid, 0, '/test-file') }
          let(:uid) { Process.uid }

          it "returns true" do
            writable = subject.writable_real?('/test-file')
            expect(writable).to be_true
          end
        end
      end

      context "when the file is group writable" do
        let(:access) { MemFs::Fake::Entry::GWRITE }

        context "and the current user is part of the owner group" do
          let(:gid) { Process.gid }

          it "returns true" do
            writable = subject.writable_real?('/test-file')
            expect(writable).to be_true
          end
        end
      end

      context "when the file is writable by anyone" do
        let(:access) { MemFs::Fake::Entry::OWRITE }

        context "and the user has no specific right on it" do
          it "returns true" do
            writable = subject.writable_real?('/test-file')
            expect(writable).to be_true
          end
        end
      end

      context "when the file does not exist" do
        it "returns false" do
          writable = subject.writable_real?('/no-file')
          expect(writable).to be_false
        end
      end
    end

    describe ".zero?" do
      context "when the named file exists" do
        context "and has a zero size" do
          it "returns true" do
            zero = subject.zero?('/test-file')
            expect(zero).to be_true
          end
        end

        context "and does not have a zero size" do
          before :each do
            File.open('/test-file', 'w') { |f| f.puts 'test' }
          end

          it "returns false" do
            zero = subject.zero?('/test-file')
            expect(zero).to be_false
          end
        end
      end

      context "when the named file does not exist" do
        it "returns false" do
          zero = subject.zero?('/no-file')
          expect(zero).to be_false
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
        expect {
          file.chown(nil, 42)
        }.to_not change{file.stat.uid}
      end

      it "ignores nil group id" do
        expect {
          file.chown(42, nil)
        }.to_not change{file.stat.gid}
      end

      it "ignores -1 user id" do
        expect {
          file.chown(-1, 42)
        }.to_not change{file.stat.uid}
      end

      it "ignores -1 group id" do
        expect {
          file.chown(42, -1)
        }.to_not change{file.stat.gid}
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
        expect(file.lstat.symlink?).to be_true
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
