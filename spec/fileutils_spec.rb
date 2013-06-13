require 'fileutils'
require 'spec_helper'

describe FileUtils do
  let(:fs) { FsFaker::FileSystem.instance }

  before :each do
    FsFaker.activate!

    FileUtils.mkdir '/test'
  end

  after :each do
    FsFaker.deactivate!
  end

  describe '.cd' do
    it "changes the current working directory" do
      FileUtils.cd '/test'
      FileUtils.pwd.should == '/test'
    end

    it "returns nil" do
      FileUtils.cd('/test').should be_nil
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
          FileUtils.pwd.should == '/test'
        end
      end

      it "resumes to the old working directory after the block execution finished" do
        FileUtils.cd '/'
        previous_dir = FileUtils.pwd
        FileUtils.cd('/test') {}
        FileUtils.pwd.should == previous_dir
      end
    end

    context "when the destination is a symlink" do
      before :each do
        FileUtils.symlink('/test', '/test-link')
      end

      it "changes directory to the last target of the link chain" do
        FileUtils.cd('/test-link')
        FileUtils.pwd.should == '/test'
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
      File.stat('/test-file').mode.should be(0100777)
    end

    it "changes permission bits on the named files (in list) to the bit pattern represented by mode" do
      FileUtils.touch ['/test-file', '/test-file2']
      FileUtils.chmod 0777, ['/test-file', '/test-file2']
      File.stat('/test-file2').mode.should be(0100777)
    end

    it "returns an array containing the file names" do
      file_names = %w[/test-file /test-file2]
      FileUtils.touch file_names
      FileUtils.chmod(0777, file_names).should == file_names
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
          File.lstat('/test-link').mode.should be(0100777)
        end

        it "doesn't change the mode of the link's target" do
          FileUtils.chmod(0777, '/test-link')
          File.lstat('/test-file').mode.should be(0100644)
        end
      end

      context "when File doesn't respond to lchmod" do
        it "does nothing" do
          FileUtils::Entry_.any_instance.stub(:have_lchmod?).and_return(false)
          FileUtils.chmod(0777, '/test-link')
          File.lstat('/test-link').mode.should be(0100644)
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
      File.stat('/test').mode.should be(0100777)
    end

    it "changes the permission bits on any sub-directory of the named entry" do
      FileUtils.chmod_R(0777, '/')
      File.stat('/test').mode.should be(0100777)
    end

    it "changes the permission bits on any descendant file of the named entry" do
      FileUtils.chmod_R(0777, '/')
      File.stat('/test/test-file').mode.should be(0100777)
    end
  end

  describe '.chown' do
    it "changes owner on the named file" do
      FileUtils.chown(42, nil, '/test')
      File.stat('/test').uid.should be(42)
    end

    it "changes owner on the named files (in list)" do
      FileUtils.touch('/test-file')
      FileUtils.chown(42, nil, ['/test', '/test-file'])
      File.stat('/test-file').uid.should be(42)
    end

    it "changes group on the named entry" do
      FileUtils.chown(nil, 42, '/test')
      File.stat('/test').gid.should be(42)
    end

    it "changes group on the named entries in list" do
      FileUtils.touch('/test-file')
      FileUtils.chown(nil, 42, ['/test', '/test-file'])
      File.stat('/test-file').gid.should be(42)
    end

    it "doesn't change user if user is nil" do
      FileUtils.chown(nil, 42, '/test')
      File.stat('/test').uid.should_not be(42)
    end

    it "doesn't change group if group is nil" do
      FileUtils.chown(42, nil, '/test')
      File.stat('/test').gid.should_not be(42)
    end

    context "when the name entry is a symlink" do
      before :each do
        FileUtils.touch '/test-file'
        FileUtils.symlink '/test-file', '/test-link'
      end

      it "changes the owner on the last target of the link chain" do
        FileUtils.chown(42, nil, '/test-link')
        File.stat('/test-file').uid.should be(42)
      end

      it "changes the group on the last target of the link chain" do
        FileUtils.chown(nil, 42, '/test-link')
        File.stat('/test-file').gid.should be(42)
      end

      it "doesn't change the owner of the symlink" do
        FileUtils.chown(42, nil, '/test-link')
        File.lstat('/test-link').uid.should_not be(42)
      end

      it "doesn't change the group of the symlink" do
        FileUtils.chown(nil, 42, '/test-link')
        File.lstat('/test-link').gid.should_not be(42)
      end
    end
  end

  describe '.chown_R' do
    before :each do
      FileUtils.touch '/test/test-file'
    end

    it "changes the owner on the named entry" do
      FileUtils.chown_R(42, nil, '/test')
      File.stat('/test').uid.should be(42)
    end

    it "changes the group on the named entry" do
      FileUtils.chown_R(nil, 42, '/test')
      File.stat('/test').gid.should be(42)
    end

    it "changes the owner on any sub-directory of the named entry" do
      FileUtils.chown_R(42, nil, '/')
      File.stat('/test').uid.should be(42)
    end

    it "changes the group on any sub-directory of the named entry" do
      FileUtils.chown_R(nil, 42, '/')
      File.stat('/test').gid.should be(42)
    end

    it "changes the owner on any descendant file of the named entry" do
      FileUtils.chown_R(42, nil, '/')
      File.stat('/test/test-file').uid.should be(42)
    end

    it "changes the group on any descendant file of the named entry" do
      FileUtils.chown_R(nil, 42, '/')
      File.stat('/test/test-file').gid.should be(42)
    end
  end

  describe '.cmp' do
    it "is an alias for #compare_file" do
      FileUtils.method(:cmp).should == FileUtils.method(:compare_file)
    end
  end

  describe '.compare_file' do
    it "returns true if the contents of a file A and a file B are identical" do
      File.open('/test-file', 'w')  { |f| f.puts "this is a test" }
      File.open('/test-file2', 'w') { |f| f.puts "this is a test" }

      FileUtils.compare_file('/test-file', '/test-file2').should be_true
    end

    it "returns false if the contents of a file A and a file B are not identical" do
      File.open('/test-file', 'w')  { |f| f.puts "this is a test" }
      File.open('/test-file2', 'w') { |f| f.puts "this is not a test" }

      FileUtils.compare_file('/test-file', '/test-file2').should be_false
    end
  end

  describe '.compare_stream' do
    it "returns true if the contents of a stream A and stream B are identical" do
      File.open('/test-file', 'w')  { |f| f.puts "this is a test" }
      File.open('/test-file2', 'w') { |f| f.puts "this is a test" }

      file1 = File.open('/test-file')
      file2 = File.open('/test-file2')

      FileUtils.compare_stream(file1, file2).should be_true
    end

    it "returns false if the contents of a stream A and stream B are not identical" do
      File.open('/test-file', 'w')  { |f| f.puts "this is a test" }
      File.open('/test-file2', 'w') { |f| f.puts "this is not a test" }

      file1 = File.open('/test-file')
      file2 = File.open('/test-file2')

      FileUtils.compare_stream(file1, file2).should be_false
    end
  end

  describe '.copy' do
    it "is an alias for #cp" do
      FileUtils.method(:copy).should == FileUtils.method(:cp)
    end
  end

  describe '.copy_entry' do
    
  end

  describe '.copy_file' do
    
  end

  describe '.copy_stream' do
    
  end

  describe '.cp' do
    before :each do
      File.open('/test-file', 'w') { |f| f.puts 'test' }
    end

    it "copies a file content +src+ to +dest+" do
      FileUtils.cp('/test-file', '/copy-file')
      File.read('/copy-file').should == "test\n"
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
        File.read('/dest/copy-file').should == "test\n"
      end
    end

    context "when src is a list of files" do
      context "when +dest+ is not a directory" do
        it "raises an error" do
          FileUtils.touch('/dest')
          FileUtils.touch('/test-file2')
          expect { FileUtils.cp(['/test-file', '/test-file2'], '/dest') }.to raise_error(Errno::ENOTDIR)
        end
      end
    end
  end

  describe '.cp_r' do
    it "copies +src+ to +dest+" do
      File.open('/test-file', 'w') { |f| f.puts 'test' }

      FileUtils.cp_r('/test-file', '/copy-file')
      File.read('/copy-file').should == "test\n"
    end

    context "when +src+ is a directory" do
      it "copies all its contents recursively" do
        FileUtils.mkdir('/test/dir')
        FileUtils.touch('/test/dir/file')

        FileUtils.cp_r('/test', '/dest')
        File.exists?('/dest/dir/file').should be_true
      end
    end

    context "when +dest+ is a directory" do
      it "copies +src+ to +dest/src+" do
        FileUtils.mkdir('/test/dir')
        FileUtils.touch('/test/dir/file')
        FileUtils.mkdir('/dest')

        FileUtils.cp_r('/test', '/dest')
        File.exists?('/dest/test/dir/file').should be_true
      end
    end

    context "when +src+ is a list of files" do
      it "copies each of them in +dest+" do
        FileUtils.mkdir('/test/dir')
        FileUtils.touch('/test/dir/file')
        FileUtils.mkdir('/test/dir2')
        FileUtils.touch('/test/dir2/file')
        FileUtils.mkdir('/dest')

        FileUtils.cp_r(['/test/dir', '/test/dir2'], '/dest')
        File.exists?('/dest/dir2/file').should be_true
      end
    end
  end

  describe '.getwd' do
    it "is an alias for #pwd" do
      FileUtils.method(:getwd).should == FileUtils.method(:pwd)
    end
  end

  describe '.identical?' do
    it "is an alias for #compare_file" do
      FileUtils.method(:identical?).should == FileUtils.method(:compare_file)
    end
  end

  describe '.install' do
    
  end

  describe '.link' do
    it "is an alias for #ln" do
      FileUtils.method(:link).should == FileUtils.method(:ln)
    end
  end

  describe '.ln' do
    before :each do
      File.open('/test-file', 'w') { |f| f.puts 'test' }
    end

    it "creates a hard link +dest+ which points to +src+" do
      FileUtils.ln('/test-file', '/test-file2')
      File.read('/test-file2').should == File.read('/test-file')
    end

    it "creates a hard link, not a symlink" do
      FileUtils.ln('/test-file', '/test-file2')
      File.symlink?('/test-file2').should be_false
    end

    context "when +dest+ already exists" do
      context "and is a directory" do
        it "creates a link dest/src" do
          FileUtils.mkdir('/test-dir')
          FileUtils.ln('/test-file', '/test-dir')
          File.read('/test-dir/test-file').should == File.read('/test-file')
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
            File.read('/test-file2').should == File.read('/test-file')
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
      File.symlink?('/test-link').should be_true
    end

    it "creates a symbolic link which points to +old+" do
      FileUtils.ln_s('/test-file', '/test-link')
      File.read('/test-link').should == File.read('/test-file')
    end

    context "when +new+ already exists" do
      context "and it is a directory" do
        it "creates a symbolic link +new/old+" do
          FileUtils.ln_s('/test-file', '/test-dir')
          File.symlink?('/test-dir/test-file').should be_true
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
            File.symlink?('/not-a-dir').should be_true
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
        File.exists?('/test-dir/test-file2').should be_true
      end

      it "creates symbolic links pointing to each item in the list" do
        FileUtils.ln_s(['/test-file', '/test-file2'], '/test-dir')
        File.read('/test-dir/test-file2').should == File.read('/test-file2')
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
      File.read('/test-file2').should == File.read('/test-file')
    end
  end

  describe '.makedirs' do
    it "is an alias for #mkdir_p" do
      FileUtils.method(:makedirs).should == FileUtils.method(:mkdir_p)
    end
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
    it "is an alias for #mkdir_p" do
      FileUtils.method(:mkpath).should == FileUtils.method(:mkdir_p)
    end
  end

  describe '.move' do
    it "is an alias for #mv" do
      FileUtils.method(:move).should == FileUtils.method(:mv)
    end
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
    it "is an alias for #rm" do
      FileUtils.method(:remove).should == FileUtils.method(:rm)
    end
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
          fs.chmod(01777, '/')
          directory = fs.find('/test-dir')
          directory.should_receive(:uid=).at_least(:once)
          FileUtils.remove_entry_secure('/test-dir')
        end

        it "calls chmod(2) on all sub directories" do
          fs.chmod(01777, '/')
          directory = fs.find('/test-dir')
          directory.should_receive(:mode=).at_least(:once)
          FileUtils.remove_entry_secure('/test-dir')
        end
      end
    end
  end

  describe '.remove_file' do
    it "removes a file path" do
      fs.touch('/test-file')
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
      fs.touch('/test-file')
      FileUtils.rm('/test-file')
      expect(File.exists?('/test-file')).to be_false
    end

    it "removes files specified in list" do
      fs.touch('/test-file', '/test-file2')
      FileUtils.rm(['/test-file', '/test-file2'])
      expect(File.exists?('/test-file2')).to be_false
    end

    it "cannot remove a directory" do
      fs.mkdir('/test-dir')
      expect { FileUtils.rm('/test-dir') }.to raise_error(Errno::EPERM)
    end

    context "when +:force+ is set" do
      it "ignores StandardError" do
        fs.mkdir('/test-dir')
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
      fs.touch('/test-file', '/test-file2')
    end

    it "removes a list of files" do
      FileUtils.rm_r(['/test-file', '/test-file2'])
      expect(File.exists?('/test-file2')).to be_false
    end

    context "when an item of the list is a directory" do
      it "removes all its contents recursively" do
        fs.mkdir('/test-dir')
        fs.touch('/test-dir/test-file')
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
      fs.mkdir('/test-dir')
      FileUtils.rmdir('/test-dir')
      expect(Dir.exists?('/test-dir')).to be_false
    end

    it "Removes a list of directories" do
      fs.mkdir('/test-dir')
      fs.mkdir('/test-dir2')
      FileUtils.rmdir(['/test-dir', '/test-dir2'])
      expect(Dir.exists?('/test-dir2')).to be_false
    end

    context "when a directory is not empty" do
      before :each do
        fs.mkdir('/test-dir')
        fs.touch('/test-dir/test-file')
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
    it "is an alias for #rm_rf" do
      FileUtils.method(:rmtree).should == FileUtils.method(:rm_rf)
    end
  end

  describe '.safe_unlink' do
    it "is an alias for #rm_f" do
      FileUtils.method(:safe_unlink).should == FileUtils.method(:rm_f)
    end
  end

  describe '.symlink' do
    it "is an alias for #ln_s" do
      FileUtils.method(:symlink).should == FileUtils.method(:ln_s)
    end
  end

  describe '.touch' do
    it "creates a file if it doesn't exist" do
      FileUtils.touch('/test-file')
      fs.find('/test-file').should_not be_nil
    end

    it "creates a list of files if they don't exist" do
      FileUtils.touch(['/test-file', '/test-file2'])
      fs.find('/test-file2').should_not be_nil
    end
  end

  describe '.uptodate?' do
    
  end
end
