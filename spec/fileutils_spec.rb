require 'date'
require 'fileutils'
require 'spec_helper'

describe FileUtils do
  before :each do
    MemFs::File.umask(0022)
    MemFs.activate!

    FileUtils.mkdir '/test'
  end

  after :each do
    MemFs.deactivate!
  end

  describe '.cd' do
    it "changes the current working directory" do
      FileUtils.cd '/test'
      expect(FileUtils.pwd).to eq('/test')
    end

    it "returns nil" do
      expect(FileUtils.cd('/test')).to be_nil
    end

    it "raises an error when the given path doesn't exist" do
      expect { FileUtils.cd('/nowhere') }.to raise_error(Errno::ENOENT)
    end

    it "raises an error when the given path is not a directory" do
      FileUtils.touch('/test-file')
      expect { FileUtils.cd('/test-file') }.to raise_error(Errno::ENOTDIR)
    end

    context "when called with a block" do
      it "changes current working directory for the block execution" do
        FileUtils.cd '/test' do
          expect(FileUtils.pwd).to eq('/test')
        end
      end

      it "resumes to the old working directory after the block execution finished" do
        FileUtils.cd '/'
        previous_dir = FileUtils.pwd
        FileUtils.cd('/test') {}
        expect(FileUtils.pwd).to eq(previous_dir)
      end
    end

    context "when the destination is a symlink" do
      before :each do
        FileUtils.symlink('/test', '/test-link')
      end

      it "changes directory to the last target of the link chain" do
        FileUtils.cd('/test-link')
        expect(FileUtils.pwd).to eq('/test')
      end

      it "raises an error if the last target of the link chain doesn't exist" do
        expect { FileUtils.cd('/nowhere-link') }.to raise_error(Errno::ENOENT)
      end
    end
  end

  describe '.chmod' do
    it "changes permission bits on the named file to the bit pattern represented by mode" do
      FileUtils.touch '/test-file'
      FileUtils.chmod 0777, '/test-file'
      expect(File.stat('/test-file').mode).to eq(0100777)
    end

    it "changes permission bits on the named files (in list) to the bit pattern represented by mode" do
      FileUtils.touch ['/test-file', '/test-file2']
      FileUtils.chmod 0777, ['/test-file', '/test-file2']
      expect(File.stat('/test-file2').mode).to eq(0100777)
    end

    it "returns an array containing the file names" do
      file_names = %w[/test-file /test-file2]
      FileUtils.touch file_names
      expect(FileUtils.chmod(0777, file_names)).to eq(file_names)
    end

    it "raises an error if an entry does not exist" do
      expect { FileUtils.chmod(0777, '/test-file') }.to raise_error(Errno::ENOENT)
    end

    context "when the named file is a symlink" do
      before :each do
        FileUtils.touch '/test-file'
        FileUtils.symlink '/test-file', '/test-link'
      end

      context "when File responds to lchmod" do
        it "changes the mode on the link" do
          FileUtils.chmod(0777, '/test-link')
          expect(File.lstat('/test-link').mode).to eq(0100777)
        end

        it "doesn't change the mode of the link's target" do
          FileUtils.chmod(0777, '/test-link')
          expect(File.lstat('/test-file').mode).to eq(0100644)
        end
      end

      context "when File doesn't respond to lchmod" do
        it "does nothing" do
          FileUtils::Entry_.any_instance.stub(:have_lchmod?).and_return(false)
          FileUtils.chmod(0777, '/test-link')
          expect(File.lstat('/test-link').mode).to eq(0100644)
        end
      end
    end
  end

  describe '.chmod_R' do
    before :each do
      FileUtils.touch '/test/test-file'
    end

    it "changes the permission bits on the named entry" do
      FileUtils.chmod_R(0777, '/test')
      expect(File.stat('/test').mode).to eq(0100777)
    end

    it "changes the permission bits on any sub-directory of the named entry" do
      FileUtils.chmod_R(0777, '/')
      expect(File.stat('/test').mode).to eq(0100777)
    end

    it "changes the permission bits on any descendant file of the named entry" do
      FileUtils.chmod_R(0777, '/')
      expect(File.stat('/test/test-file').mode).to eq(0100777)
    end
  end

  describe '.chown' do
    it "changes owner on the named file" do
      FileUtils.chown(42, nil, '/test')
      expect(File.stat('/test').uid).to eq(42)
    end

    it "changes owner on the named files (in list)" do
      FileUtils.touch('/test-file')
      FileUtils.chown(42, nil, ['/test', '/test-file'])
      expect(File.stat('/test-file').uid).to eq(42)
    end

    it "changes group on the named entry" do
      FileUtils.chown(nil, 42, '/test')
      expect(File.stat('/test').gid).to eq(42)
    end

    it "changes group on the named entries in list" do
      FileUtils.touch('/test-file')
      FileUtils.chown(nil, 42, ['/test', '/test-file'])
      expect(File.stat('/test-file').gid).to eq(42)
    end

    it "doesn't change user if user is nil" do
      FileUtils.chown(nil, 42, '/test')
      expect(File.stat('/test').uid).not_to be(42)
    end

    it "doesn't change group if group is nil" do
      FileUtils.chown(42, nil, '/test')
      expect(File.stat('/test').gid).not_to be(42)
    end

    context "when the name entry is a symlink" do
      before :each do
        FileUtils.touch '/test-file'
        FileUtils.symlink '/test-file', '/test-link'
      end

      it "changes the owner on the last target of the link chain" do
        FileUtils.chown(42, nil, '/test-link')
        expect(File.stat('/test-file').uid).to eq(42)
      end

      it "changes the group on the last target of the link chain" do
        FileUtils.chown(nil, 42, '/test-link')
        expect(File.stat('/test-file').gid).to eq(42)
      end

      it "doesn't change the owner of the symlink" do
        FileUtils.chown(42, nil, '/test-link')
        expect(File.lstat('/test-link').uid).not_to be(42)
      end

      it "doesn't change the group of the symlink" do
        FileUtils.chown(nil, 42, '/test-link')
        expect(File.lstat('/test-link').gid).not_to be(42)
      end
    end
  end

  describe '.chown_R' do
    before :each do
      FileUtils.touch '/test/test-file'
    end

    it "changes the owner on the named entry" do
      FileUtils.chown_R(42, nil, '/test')
      expect(File.stat('/test').uid).to eq(42)
    end

    it "changes the group on the named entry" do
      FileUtils.chown_R(nil, 42, '/test')
      expect(File.stat('/test').gid).to eq(42)
    end

    it "changes the owner on any sub-directory of the named entry" do
      FileUtils.chown_R(42, nil, '/')
      expect(File.stat('/test').uid).to eq(42)
    end

    it "changes the group on any sub-directory of the named entry" do
      FileUtils.chown_R(nil, 42, '/')
      expect(File.stat('/test').gid).to eq(42)
    end

    it "changes the owner on any descendant file of the named entry" do
      FileUtils.chown_R(42, nil, '/')
      expect(File.stat('/test/test-file').uid).to eq(42)
    end

    it "changes the group on any descendant file of the named entry" do
      FileUtils.chown_R(nil, 42, '/')
      expect(File.stat('/test/test-file').gid).to eq(42)
    end
  end

  describe '.cmp' do
    it_behaves_like 'aliased method', :cmp, :compare_file
  end

  describe '.compare_file' do
    it "returns true if the contents of a file A and a file B are identical" do
      File.open('/test-file', 'w')  { |f| f.puts "this is a test" }
      File.open('/test-file2', 'w') { |f| f.puts "this is a test" }

      expect(FileUtils.compare_file('/test-file', '/test-file2')).to be_true
    end

    it "returns false if the contents of a file A and a file B are not identical" do
      File.open('/test-file', 'w')  { |f| f.puts "this is a test" }
      File.open('/test-file2', 'w') { |f| f.puts "this is not a test" }

      expect(FileUtils.compare_file('/test-file', '/test-file2')).to be_false
    end
  end

  describe '.compare_stream' do
    it "returns true if the contents of a stream A and stream B are identical" do
      File.open('/test-file', 'w')  { |f| f.puts "this is a test" }
      File.open('/test-file2', 'w') { |f| f.puts "this is a test" }

      file1 = File.open('/test-file')
      file2 = File.open('/test-file2')

      expect(FileUtils.compare_stream(file1, file2)).to be_true
    end

    it "returns false if the contents of a stream A and stream B are not identical" do
      File.open('/test-file', 'w')  { |f| f.puts "this is a test" }
      File.open('/test-file2', 'w') { |f| f.puts "this is not a test" }

      file1 = File.open('/test-file')
      file2 = File.open('/test-file2')

      expect(FileUtils.compare_stream(file1, file2)).to be_false
    end
  end

  describe '.copy' do
    it_behaves_like 'aliased method', :copy, :cp
  end

  describe '.copy_entry' do
    it "copies a file system entry +src+ to +dest+" do
      File.open('/test-file', 'w') { |f| f.puts 'test' }
      FileUtils.copy_entry('/test-file', '/test-copy')
      expect(File.read('/test-copy')).to eq("test\n")
    end

    it "preserves file types" do
      FileUtils.touch('/test-file')
      FileUtils.symlink('/test-file', '/test-link')
      FileUtils.copy_entry('/test-link', '/test-copy')
      expect(File.symlink?('/test-copy')).to be_true
    end

    context "when +src+ does not exist" do
      it "raises an exception" do
        expect {
          FileUtils.copy_entry('/test-file', '/test-copy')
        }.to raise_error(RuntimeError)
      end
    end

    context "when +preserve+ is true" do
      let(:time) { Date.parse('2013-01-01') }

      before :each do
        FileUtils.touch('/test-file')
        FileUtils.chown(1042, 1042, '/test-file')
        FileUtils.chmod(0777, '/test-file')
        fs.find('/test-file').mtime = time
        FileUtils.copy_entry('/test-file', '/test-copy', true)
      end

      it "preserves owner" do
        expect(File.stat('/test-copy').uid).to eq(1042)
      end

      it "preserves group" do
        expect(File.stat('/test-copy').gid).to eq(1042)
      end

      it "preserves permissions" do
        expect(File.stat('/test-copy').mode).to eq(0100777)
      end

      it "preserves modified time" do
        expect(File.stat('/test-copy').mtime).to eq(time)
      end
    end

    context "when +dest+ already exists" do
      it "overwrite it" do
        File.open('/test-file', 'w') { |f| f.puts 'test' }
        FileUtils.touch('/test-copy')
        FileUtils.copy_entry('/test-file', '/test-copy')
        expect(File.read('/test-copy')).to eq("test\n")
      end
    end

    context "when +remove_destination+ is true" do
      it "removes each destination file before copy" do
        FileUtils.touch(['/test-file', '/test-copy'])
        File.should_receive(:unlink).with('/test-copy')
        FileUtils.copy_entry('/test-file', '/test-copy', false, false, true)
      end
    end

    context "when +src+ is a directory" do
      it "copies its contents recursively" do
        FileUtils.mkdir_p('/test-dir/test-sub-dir')
        FileUtils.copy_entry('/test-dir', '/test-copy')
        expect(Dir.exists?('/test-copy/test-sub-dir')).to be_true
      end
    end
  end

  describe '.copy_file' do
    it "copies file contents of src to dest" do
      File.open('/test-file', 'w') { |f| f.puts 'test' }
      FileUtils.copy_file('/test-file', '/test-file2')
      expect(File.read('/test-file2')).to eq("test\n")
    end
  end

  describe '.copy_stream' do
    # This method is not implemented since it is delegated to the IO class.
  end

  describe '.cp' do
    before :each do
      File.open('/test-file', 'w') { |f| f.puts 'test' }
    end

    it "copies a file content +src+ to +dest+" do
      FileUtils.cp('/test-file', '/copy-file')
      expect(File.read('/copy-file')).to eq("test\n")
    end

    context "when +src+ and +dest+ are the same file" do
      it "raises an error" do
        expect { FileUtils.cp('/test-file', '/test-file') }.to raise_error(ArgumentError)
      end
    end

    context "when +dest+ is a directory" do
      it "copies +src+ to +dest/src+" do
        FileUtils.mkdir('/dest')
        FileUtils.cp('/test-file', '/dest/copy-file')
        expect(File.read('/dest/copy-file')).to eq("test\n")
      end
    end

    context "when src is a list of files" do
      context "when +dest+ is not a directory" do
        it "raises an error" do
          FileUtils.touch(['/dest', '/test-file2'])
          expect { FileUtils.cp(['/test-file', '/test-file2'], '/dest') }.to raise_error(Errno::ENOTDIR)
        end
      end
    end
  end

  describe '.cp_r' do
    it "copies +src+ to +dest+" do
      File.open('/test-file', 'w') { |f| f.puts 'test' }

      FileUtils.cp_r('/test-file', '/copy-file')
      expect(File.read('/copy-file')).to eq("test\n")
    end

    context "when +src+ is a directory" do
      it "copies all its contents recursively" do
        FileUtils.mkdir('/test/dir')
        FileUtils.touch('/test/dir/file')

        FileUtils.cp_r('/test', '/dest')
        expect(File.exists?('/dest/dir/file')).to be_true
      end
    end

    context "when +dest+ is a directory" do
      it "copies +src+ to +dest/src+" do
        FileUtils.mkdir(['/test/dir', '/dest'])
        FileUtils.touch('/test/dir/file')

        FileUtils.cp_r('/test', '/dest')
        expect(File.exists?('/dest/test/dir/file')).to be_true
      end
    end

    context "when +src+ is a list of files" do
      it "copies each of them in +dest+" do
        FileUtils.mkdir(['/test/dir', '/test/dir2', '/dest'])
        FileUtils.touch(['/test/dir/file', '/test/dir2/file'])

        FileUtils.cp_r(['/test/dir', '/test/dir2'], '/dest')
        expect(File.exists?('/dest/dir2/file')).to be_true
      end
    end
  end

  describe '.getwd' do
    it_behaves_like 'aliased method', :getwd, :pwd
  end

  describe '.identical?' do
    it_behaves_like 'aliased method', :identical?, :compare_file
  end

  describe '.install' do
    before :each do
      File.open('/test-file', 'w') { |f| f.puts 'test' }
    end

    it "copies +src+ to +dest+" do
      FileUtils.install('/test-file', '/test-file2')
      expect(File.read('/test-file2')).to eq("test\n")
    end

    context "when +:mode+ is set" do
      it "changes the permission mode to +mode+" do
        File.should_receive(:chmod).with(0777, '/test-file2')
        FileUtils.install('/test-file', '/test-file2', mode: 0777)
      end
    end

    context "when +src+ and +dest+ are the same file" do
      it "raises an exception" do
        expect {
          FileUtils.install('/test-file', '/test-file')
        }.to raise_exception(ArgumentError)
      end
    end

    context "when +dest+ already exists" do
      it "removes destination before copy" do
        File.should_receive(:unlink).with('/test-file2')
        FileUtils.install('/test-file', '/test-file2')
      end

      context "and +dest+ is a directory" do
        it "installs +src+ in dest/src" do
          FileUtils.mkdir('/test-dir')
          FileUtils.install('/test-file', '/test-dir')
          expect(File.read('/test-dir/test-file')).to eq("test\n")
        end
      end
    end
  end

  describe '.link' do
    it_behaves_like 'aliased method', :link, :ln
  end

  describe '.ln' do
    before :each do
      File.open('/test-file', 'w') { |f| f.puts 'test' }
    end

    it "creates a hard link +dest+ which points to +src+" do
      FileUtils.ln('/test-file', '/test-file2')
      expect(File.read('/test-file2')).to eq(File.read('/test-file'))
    end

    it "creates a hard link, not a symlink" do
      FileUtils.ln('/test-file', '/test-file2')
      expect(File.symlink?('/test-file2')).to be_false
    end

    context "when +dest+ already exists" do
      context "and is a directory" do
        it "creates a link dest/src" do
          FileUtils.mkdir('/test-dir')
          FileUtils.ln('/test-file', '/test-dir')
          expect(File.read('/test-dir/test-file')).to eq(File.read('/test-file'))
        end
      end

      context "and it is not a directory" do
        it "raises an exception" do
          FileUtils.touch('/test-file2')
          expect { FileUtils.ln('/test-file', '/test-file2') }.to raise_error(SystemCallError)
        end

        context "and +:force+ is set" do
          it "overwrites +dest+" do
            FileUtils.touch('/test-file2')
            FileUtils.ln('/test-file', '/test-file2', force: true)
            expect(File.read('/test-file2')).to eq(File.read('/test-file'))
          end
        end
      end
    end

    context "when passing a list of paths" do
      it "creates a link for each path in +destdir+" do
        FileUtils.touch('/test-file2')
        FileUtils.mkdir('/test-dir')
        FileUtils.ln(['/test-file', '/test-file2'], '/test-dir')
      end

      context "and +destdir+ is not a directory" do
        it "raises an exception" do
          FileUtils.touch(['/test-file2', '/not-a-dir'])
          expect {
            FileUtils.ln(['/test-file', '/test-file2'], '/not-a-dir')
          }.to raise_error(Errno::ENOTDIR)
        end
      end
    end
  end

  describe '.ln_s' do
    before :each do
      File.open('/test-file', 'w') { |f| f.puts 'test' }
      FileUtils.touch('/not-a-dir')
      FileUtils.mkdir('/test-dir')
    end

    it "creates a symbolic link +new+" do
      FileUtils.ln_s('/test-file', '/test-link')
      expect(File.symlink?('/test-link')).to be_true
    end

    it "creates a symbolic link which points to +old+" do
      FileUtils.ln_s('/test-file', '/test-link')
      expect(File.read('/test-link')).to eq(File.read('/test-file'))
    end

    context "when +new+ already exists" do
      context "and it is a directory" do
        it "creates a symbolic link +new/old+" do
          FileUtils.ln_s('/test-file', '/test-dir')
          expect(File.symlink?('/test-dir/test-file')).to be_true
        end
      end

      context "and it is not a directory" do
        it "raises an exeption" do
          expect {
            FileUtils.ln_s('/test-file', '/not-a-dir')
          }.to raise_error(Errno::EEXIST)
        end

        context "and +:force+ is set" do
          it "overwrites +new+" do
            FileUtils.ln_s('/test-file', '/not-a-dir', force: true)
            expect(File.symlink?('/not-a-dir')).to be_true
          end
        end
      end
    end

    context "when passing a list of paths" do
      before :each do
        File.open('/test-file2', 'w') { |f| f.puts 'test2' }
      end

      it "creates several symbolic links in +destdir+" do
        FileUtils.ln_s(['/test-file', '/test-file2'], '/test-dir')
        expect(File.exists?('/test-dir/test-file2')).to be_true
      end

      it "creates symbolic links pointing to each item in the list" do
        FileUtils.ln_s(['/test-file', '/test-file2'], '/test-dir')
        expect(File.read('/test-dir/test-file2')).to eq(File.read('/test-file2'))
      end

      context "when +destdir+ is not a directory" do
        it "raises an error" do
          expect {
            FileUtils.ln_s(['/test-file', '/test-file2'], '/not-a-dir')
          }.to raise_error(Errno::ENOTDIR)
        end
      end
    end
  end

  describe '.ln_sf' do
    it "calls ln_s with +:force+ set to true" do
      File.open('/test-file', 'w') { |f| f.puts 'test' }
      File.open('/test-file2', 'w') { |f| f.puts 'test2' }
      FileUtils.ln_sf('/test-file', '/test-file2')
      expect(File.read('/test-file2')).to eq(File.read('/test-file'))
    end
  end

  describe '.makedirs' do
    it_behaves_like 'aliased method', :makedirs, :mkdir_p
  end

  describe '.mkdir' do
    it "creates one directory" do
      FileUtils.mkdir('/test-dir')
      expect(File.directory?('/test-dir')).to be_true
    end

    context "when passing a list of paths" do
      it "creates several directories" do
        FileUtils.mkdir(['/test-dir', '/test-dir2'])
        expect(File.directory?('/test-dir2')).to be_true
      end
    end
  end

  describe '.mkdir_p' do
    it "creates a directory" do
      FileUtils.mkdir_p('/test-dir')
      expect(File.directory?('/test-dir')).to be_true
    end

    it "creates all the parent directories" do
      FileUtils.mkdir_p('/path/to/some/test-dir')
      expect(File.directory?('/path/to/some')).to be_true
    end

    context "when passing a list of paths" do
      it "creates each directory" do
        FileUtils.mkdir_p(['/test-dir', '/test-dir'])
        expect(File.directory?('/test-dir')).to be_true
      end

      it "creates each directory's parents" do
        FileUtils.mkdir_p(['/test-dir', '/path/to/some/test-dir'])
        expect(File.directory?('/path/to/some')).to be_true
      end
    end
  end

  describe '.mkpath' do
    it_behaves_like 'aliased method', :mkpath, :mkdir_p
  end

  describe '.move' do
    it_behaves_like 'aliased method', :move, :mv
  end

  describe '.mv' do
    it "moves +src+ to +dest+" do
      FileUtils.touch('/test-file')
      FileUtils.mv('/test-file', '/test-file2')
      expect(File.exists?('/test-file2')).to be_true
    end

    it "removes +src+" do
      FileUtils.touch('/test-file')
      FileUtils.mv('/test-file', '/test-file2')
      expect(File.exists?('/test-file')).to be_false
    end

    context "when +dest+ already exists" do
      context "and is a directory" do
        it "moves +src+ to dest/src" do
          FileUtils.touch('/test-file')
          FileUtils.mkdir('/test-dir')
          FileUtils.mv('/test-file', '/test-dir')
          expect(File.exists?('/test-dir/test-file')).to be_true
        end
      end

      context "and +dest+ is not a directory" do
        it "it overwrites +dest+" do
          File.open('/test-file', 'w') { |f| f.puts 'test' }
          FileUtils.touch('/test-file2')
          FileUtils.mv('/test-file', '/test-file2')
          expect(File.read('/test-file2')).to eq("test\n")
        end
      end
    end
  end

  describe '.pwd' do
    it "returns the name of the current directory" do
      FileUtils.cd '/test'
      expect(FileUtils.pwd).to eq('/test')
    end
  end

  describe '.remove' do
    it_behaves_like 'aliased method', :remove, :rm
  end

  describe '.remove_dir' do
    it "removes the given directory +dir+" do
      FileUtils.mkdir('/test-dir')
      FileUtils.remove_dir('/test-dir')
      expect(File.exists?('/test-dir')).to be_false
    end

    it "removes the contents of the given directory +dir+" do
      FileUtils.mkdir_p('/test-dir/test-sub-dir')
      FileUtils.remove_dir('/test-dir')
      expect(File.exists?('/test-dir/test-sub-dir')).to be_false
    end

    context "when +force+ is set" do
      it "ignores standard errors" do
        expect { FileUtils.remove_dir('/test-dir', true) }.not_to raise_error
      end
    end
  end

  describe '.remove_entry' do
    it "removes a file system entry +path+" do
      FileUtils.touch('/test-file')
      FileUtils.remove_entry('/test-file')
      expect(File.exists?('/test-file')).to be_false
    end

    context "when +path+ is a directory" do
      it "removes it recursively" do
        FileUtils.mkdir_p('/test-dir/test-sub-dir')
        FileUtils.remove_entry('/test-dir')
        expect(Dir.exists?('/test-dir')).to be_false
      end
    end
  end

  describe '.remove_entry_secure' do
    before :each do
      FileUtils.mkdir_p('/test-dir/test-sub-dir')
    end

    it "removes a file system entry +path+" do
      FileUtils.remove_entry_secure('/test-dir')
      expect(Dir.exists?('/test-dir')).to be_false
    end

    context "when +path+ is a directory" do
      it "removes it recursively" do
        FileUtils.remove_entry_secure('/test-dir')
        expect(Dir.exists?('/test-dir/test-sub-dir')).to be_false
      end

      context "and is word writable" do
        it "calls chown(2) on it" do
          FileUtils.chmod(01777, '/')
          directory = fs.find('/test-dir')
          directory.should_receive(:uid=).at_least(:once)
          FileUtils.remove_entry_secure('/test-dir')
        end

        it "calls chmod(2) on all sub directories" do
          FileUtils.chmod(01777, '/')
          directory = fs.find('/test-dir')
          directory.should_receive(:mode=).at_least(:once)
          FileUtils.remove_entry_secure('/test-dir')
        end
      end
    end
  end

  describe '.remove_file' do
    it "removes a file path" do
      FileUtils.touch('/test-file')
      FileUtils.remove_file('/test-file')
      expect(File.exists?('/test-file')).to be_false
    end

    context "when +force+ is set" do
      it "ignores StandardError" do
        expect { FileUtils.remove_file('/no-file', true) }.not_to raise_error
      end
    end
  end

  describe '.rm' do
    it "removes the specified file" do
      FileUtils.touch('/test-file')
      FileUtils.rm('/test-file')
      expect(File.exists?('/test-file')).to be_false
    end

    it "removes files specified in list" do
      FileUtils.touch(['/test-file', '/test-file2'])
      FileUtils.rm(['/test-file', '/test-file2'])
      expect(File.exists?('/test-file2')).to be_false
    end

    it "cannot remove a directory" do
      FileUtils.mkdir('/test-dir')
      expect { FileUtils.rm('/test-dir') }.to raise_error(Errno::EPERM)
    end

    context "when +:force+ is set" do
      it "ignores StandardError" do
        FileUtils.mkdir('/test-dir')
        expect {
          FileUtils.rm('/test-dir', force: true)
        }.not_to raise_error(Errno::EPERM)
      end
    end
  end

  describe '.rm_f' do
    it "calls rm with +:force+ set to true" do
      FileUtils.should_receive(:rm).with('test', force: true)
      FileUtils.rm_f('test')
    end
  end

  describe '.rm_r' do
    before :each do
      FileUtils.touch(['/test-file', '/test-file2'])
    end

    it "removes a list of files" do
      FileUtils.rm_r(['/test-file', '/test-file2'])
      expect(File.exists?('/test-file2')).to be_false
    end

    context "when an item of the list is a directory" do
      it "removes all its contents recursively" do
        FileUtils.mkdir('/test-dir')
        FileUtils.touch('/test-dir/test-file')
        FileUtils.rm_r(['/test-file', '/test-file2', '/test-dir'])
        expect(File.exists?('/test-dir/test-file')).to be_false
      end
    end

    context "when +:force+ is set" do
      it "ignores StandardError" do
        expect {
          FileUtils.rm_r(['/no-file'], force: true)
        }.not_to raise_error(Errno::ENOENT)
      end
    end
  end

  describe '.rm_rf' do
    it "calls rm with +:force+ set to true" do
      FileUtils.should_receive(:rm_r).with('test', force: true)
      FileUtils.rm_rf('test')
    end
  end

  describe '.rmdir' do
    it "Removes a directory" do
      FileUtils.mkdir('/test-dir')
      FileUtils.rmdir('/test-dir')
      expect(Dir.exists?('/test-dir')).to be_false
    end

    it "Removes a list of directories" do
      FileUtils.mkdir('/test-dir')
      FileUtils.mkdir('/test-dir2')
      FileUtils.rmdir(['/test-dir', '/test-dir2'])
      expect(Dir.exists?('/test-dir2')).to be_false
    end

    context "when a directory is not empty" do
      before :each do
        FileUtils.mkdir('/test-dir')
        FileUtils.touch('/test-dir/test-file')
      end

      it "ignores errors" do
        expect { FileUtils.rmdir('/test-dir') }.not_to raise_error
      end

      it "doesn't remove the directory" do
        FileUtils.rmdir('/test-dir')
        expect(Dir.exists?('/test-dir')).to be_true
      end
    end
  end

  describe '.rmtree' do
    it_behaves_like 'aliased method', :rmtree, :rm_rf
  end

  describe '.safe_unlink' do
    it_behaves_like 'aliased method', :safe_unlink, :rm_f
  end

  describe '.symlink' do
    it_behaves_like 'aliased method', :symlink, :ln_s
  end

  describe '.touch' do
    it "creates a file if it doesn't exist" do
      FileUtils.touch('/test-file')
      expect(fs.find('/test-file')).not_to be_nil
    end

    it "creates a list of files if they don't exist" do
      FileUtils.touch(['/test-file', '/test-file2'])
      expect(fs.find('/test-file2')).not_to be_nil
    end
  end

  describe '.uptodate?' do
    before :each do
      FileUtils.touch('/test-file')
      FileUtils.touch('/old-file')
      fs.find!('/old-file').mtime = Time.now - 3600
    end

    it "returns true if +newer+ is newer than all +old_list+" do
      expect(FileUtils.uptodate?('/test-file', ['/old-file'])).to be_true
    end

    context "when +newer+ does not exist" do
      it "consideres it as older" do
        expect(FileUtils.uptodate?('/no-file', ['/old-file'])).to be_false
      end
    end

    context "when a item of +old_list+ does not exist" do
      it "consideres it as older than +newer+" do
        uptodate = FileUtils.uptodate?('/test-file', ['/old-file', '/no-file'])
        expect(uptodate).to be_true
      end
    end
  end
end
