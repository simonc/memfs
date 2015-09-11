require 'date'
require 'fileutils'
require 'spec_helper'

describe FileUtils do
  before :each do
    MemFs::File.umask(0020)
    MemFs.activate!

    described_class.mkdir '/test'
  end

  after :each do
    MemFs.deactivate!
  end

  describe '.cd' do
    it 'changes the current working directory' do
      described_class.cd '/test'
      expect(described_class.pwd).to eq('/test')
    end

    it 'returns nil' do
      expect(described_class.cd('/test')).to be_nil
    end

    it "raises an error when the given path doesn't exist" do
      expect { described_class.cd('/nowhere') }.to raise_specific_error(Errno::ENOENT)
    end

    it 'raises an error when the given path is not a directory' do
      described_class.touch('/test-file')
      expect { described_class.cd('/test-file') }.to raise_specific_error(Errno::ENOTDIR)
    end

    context 'when called with a block' do
      it 'changes current working directory for the block execution' do
        described_class.cd '/test' do
          expect(described_class.pwd).to eq('/test')
        end
      end

      it 'resumes to the old working directory after the block execution finished' do
        described_class.cd '/'
        expect { described_class.cd('/test') {} }.to_not change { described_class.pwd }
      end
    end

    context 'when the destination is a symlink' do
      before :each do
        described_class.symlink('/test', '/test-link')
      end

      it 'changes directory to the last target of the link chain' do
        described_class.cd('/test-link')
        expect(described_class.pwd).to eq('/test')
      end

      it "raises an error if the last target of the link chain doesn't exist" do
        expect { described_class.cd('/nowhere-link') }.to raise_specific_error(Errno::ENOENT)
      end
    end
  end

  describe '.chmod' do
    it 'changes permission bits on the named file to the bit pattern represented by mode' do
      described_class.touch '/test-file'
      described_class.chmod 0777, '/test-file'
      expect(File.stat('/test-file').mode).to eq(0100777)
    end

    it 'changes permission bits on the named files (in list) to the bit pattern represented by mode' do
      described_class.touch ['/test-file', '/test-file2']
      described_class.chmod 0777, ['/test-file', '/test-file2']
      expect(File.stat('/test-file2').mode).to eq(0100777)
    end

    it 'returns an array containing the file names' do
      file_names = %w[/test-file /test-file2]
      described_class.touch file_names
      expect(described_class.chmod(0777, file_names)).to eq(file_names)
    end

    it 'raises an error if an entry does not exist' do
      expect { described_class.chmod(0777, '/test-file') }.to raise_specific_error(Errno::ENOENT)
    end

    context 'when the named file is a symlink' do
      before :each do
        described_class.touch '/test-file'
        described_class.symlink '/test-file', '/test-link'
      end

      context 'when File responds to lchmod' do
        it 'changes the mode on the link' do
          described_class.chmod(0777, '/test-link')
          expect(File.lstat('/test-link').mode).to eq(0100777)
        end

        it "doesn't change the mode of the link's target" do
          mode = File.lstat('/test-file').mode
          described_class.chmod(0777, '/test-link')
          expect(File.lstat('/test-file').mode).to eq(mode)
        end
      end

      context "when File doesn't respond to lchmod" do
        it 'does nothing' do
          allow_any_instance_of(described_class::Entry_).to \
            receive_messages(have_lchmod?: false)
          mode = File.lstat('/test-link').mode
          described_class.chmod(0777, '/test-link')
          expect(File.lstat('/test-link').mode).to eq(mode)
        end
      end
    end
  end

  describe '.chmod_R' do
    before :each do
      described_class.touch '/test/test-file'
    end

    it 'changes the permission bits on the named entry' do
      described_class.chmod_R(0777, '/test')
      expect(File.stat('/test').mode).to eq(0100777)
    end

    it 'changes the permission bits on any sub-directory of the named entry' do
      described_class.chmod_R(0777, '/')
      expect(File.stat('/test').mode).to eq(0100777)
    end

    it 'changes the permission bits on any descendant file of the named entry' do
      described_class.chmod_R(0777, '/')
      expect(File.stat('/test/test-file').mode).to eq(0100777)
    end
  end

  describe '.chown' do
    it 'changes owner on the named file' do
      described_class.chown(42, nil, '/test')
      expect(File.stat('/test').uid).to eq(42)
    end

    it 'changes owner on the named files (in list)' do
      described_class.touch('/test-file')
      described_class.chown(42, nil, ['/test', '/test-file'])
      expect(File.stat('/test-file').uid).to eq(42)
    end

    it 'changes group on the named entry' do
      described_class.chown(nil, 42, '/test')
      expect(File.stat('/test').gid).to eq(42)
    end

    it 'changes group on the named entries in list' do
      described_class.touch('/test-file')
      described_class.chown(nil, 42, ['/test', '/test-file'])
      expect(File.stat('/test-file').gid).to eq(42)
    end

    it "doesn't change user if user is nil" do
      described_class.chown(nil, 42, '/test')
      expect(File.stat('/test').uid).not_to be(42)
    end

    it "doesn't change group if group is nil" do
      described_class.chown(42, nil, '/test')
      expect(File.stat('/test').gid).not_to be(42)
    end

    context 'when the name entry is a symlink' do
      before :each do
        described_class.touch '/test-file'
        described_class.symlink '/test-file', '/test-link'
      end

      it 'changes the owner on the last target of the link chain' do
        described_class.chown(42, nil, '/test-link')
        expect(File.stat('/test-file').uid).to eq(42)
      end

      it 'changes the group on the last target of the link chain' do
        described_class.chown(nil, 42, '/test-link')
        expect(File.stat('/test-file').gid).to eq(42)
      end

      it "doesn't change the owner of the symlink" do
        described_class.chown(42, nil, '/test-link')
        expect(File.lstat('/test-link').uid).not_to be(42)
      end

      it "doesn't change the group of the symlink" do
        described_class.chown(nil, 42, '/test-link')
        expect(File.lstat('/test-link').gid).not_to be(42)
      end
    end
  end

  describe '.chown_R' do
    before :each do
      described_class.touch '/test/test-file'
    end

    it 'changes the owner on the named entry' do
      described_class.chown_R(42, nil, '/test')
      expect(File.stat('/test').uid).to eq(42)
    end

    it 'changes the group on the named entry' do
      described_class.chown_R(nil, 42, '/test')
      expect(File.stat('/test').gid).to eq(42)
    end

    it 'changes the owner on any sub-directory of the named entry' do
      described_class.chown_R(42, nil, '/')
      expect(File.stat('/test').uid).to eq(42)
    end

    it 'changes the group on any sub-directory of the named entry' do
      described_class.chown_R(nil, 42, '/')
      expect(File.stat('/test').gid).to eq(42)
    end

    it 'changes the owner on any descendant file of the named entry' do
      described_class.chown_R(42, nil, '/')
      expect(File.stat('/test/test-file').uid).to eq(42)
    end

    it 'changes the group on any descendant file of the named entry' do
      described_class.chown_R(nil, 42, '/')
      expect(File.stat('/test/test-file').gid).to eq(42)
    end
  end

  describe '.cmp' do
    it_behaves_like 'aliased method', :cmp, :compare_file
  end

  describe '.compare_file' do
    it 'returns true if the contents of a file A and a file B are identical' do
      File.open('/test-file', 'w')  { |f| f.puts 'this is a test' }
      File.open('/test-file2', 'w') { |f| f.puts 'this is a test' }

      expect(described_class.compare_file('/test-file', '/test-file2')).to be true
    end

    it 'returns false if the contents of a file A and a file B are not identical' do
      File.open('/test-file', 'w')  { |f| f.puts 'this is a test' }
      File.open('/test-file2', 'w') { |f| f.puts 'this is not a test' }

      expect(described_class.compare_file('/test-file', '/test-file2')).to be false
    end
  end

  describe '.compare_stream' do
    it 'returns true if the contents of a stream A and stream B are identical' do
      File.open('/test-file', 'w')  { |f| f.puts 'this is a test' }
      File.open('/test-file2', 'w') { |f| f.puts 'this is a test' }

      file1 = File.open('/test-file')
      file2 = File.open('/test-file2')

      expect(described_class.compare_stream(file1, file2)).to be true
    end

    it 'returns false if the contents of a stream A and stream B are not identical' do
      File.open('/test-file', 'w')  { |f| f.puts 'this is a test' }
      File.open('/test-file2', 'w') { |f| f.puts 'this is not a test' }

      file1 = File.open('/test-file')
      file2 = File.open('/test-file2')

      expect(described_class.compare_stream(file1, file2)).to be false
    end
  end

  describe '.copy' do
    it_behaves_like 'aliased method', :copy, :cp
  end

  describe '.copy_entry' do
    it 'copies a file system entry +src+ to +dest+' do
      File.open('/test-file', 'w') { |f| f.puts 'test' }
      described_class.copy_entry('/test-file', '/test-copy')
      expect(File.read('/test-copy')).to eq("test\n")
    end

    it 'preserves file types' do
      described_class.touch('/test-file')
      described_class.symlink('/test-file', '/test-link')
      described_class.copy_entry('/test-link', '/test-copy')
      expect(File.symlink?('/test-copy')).to be true
    end

    context 'when +src+ does not exist' do
      it 'raises an exception' do
        expect {
          described_class.copy_entry('/test-file', '/test-copy')
        }.to raise_specific_error(RuntimeError)
      end
    end

    context 'when +preserve+ is true' do
      let(:time) { Date.parse('2013-01-01') }

      before :each do
        described_class.touch('/test-file')
        described_class.chown(1042, 1042, '/test-file')
        described_class.chmod(0777, '/test-file')
        _fs.find('/test-file').mtime = time
        described_class.copy_entry('/test-file', '/test-copy', true)
      end

      it 'preserves owner' do
        expect(File.stat('/test-copy').uid).to eq(1042)
      end

      it 'preserves group' do
        expect(File.stat('/test-copy').gid).to eq(1042)
      end

      it 'preserves permissions' do
        expect(File.stat('/test-copy').mode).to eq(0100777)
      end

      it 'preserves modified time' do
        expect(File.stat('/test-copy').mtime).to eq(time)
      end
    end

    context 'when +dest+ already exists' do
      it 'overwrite it' do
        File.open('/test-file', 'w') { |f| f.puts 'test' }
        described_class.touch('/test-copy')
        described_class.copy_entry('/test-file', '/test-copy')
        expect(File.read('/test-copy')).to eq("test\n")
      end
    end

    context 'when +remove_destination+ is true' do
      it 'removes each destination file before copy' do
        described_class.touch(['/test-file', '/test-copy'])
        expect(File).to receive(:unlink).with('/test-copy')
        described_class.copy_entry('/test-file', '/test-copy', false, false, true)
      end
    end

    context 'when +src+ is a directory' do
      it 'copies its contents recursively' do
        described_class.mkdir_p('/test-dir/test-sub-dir')
        described_class.copy_entry('/test-dir', '/test-copy')
        expect(Dir.exist?('/test-copy/test-sub-dir')).to be true
      end
    end
  end

  describe '.copy_file' do
    it 'copies file contents of src to dest' do
      File.open('/test-file', 'w') { |f| f.puts 'test' }
      described_class.copy_file('/test-file', '/test-file2')
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

    it 'copies a file content +src+ to +dest+' do
      described_class.cp('/test-file', '/copy-file')
      expect(File.read('/copy-file')).to eq("test\n")
    end

    context 'when +src+ and +dest+ are the same file' do
      it 'raises an error' do
        expect {
          described_class.cp('/test-file', '/test-file')
        }.to raise_specific_error(ArgumentError)
      end
    end

    context 'when +dest+ is a directory' do
      it 'copies +src+ to +dest/src+' do
        described_class.mkdir('/dest')
        described_class.cp('/test-file', '/dest/copy-file')
        expect(File.read('/dest/copy-file')).to eq("test\n")
      end
    end

    context 'when src is a list of files' do
      context 'when +dest+ is not a directory' do
        it 'raises an error' do
          described_class.touch(['/dest', '/test-file2'])
          expect {
            described_class.cp(['/test-file', '/test-file2'], '/dest')
          }.to raise_specific_error(Errno::ENOTDIR)
        end
      end
    end
  end

  describe '.cp_r' do
    it 'copies +src+ to +dest+' do
      File.open('/test-file', 'w') { |f| f.puts 'test' }

      described_class.cp_r('/test-file', '/copy-file')
      expect(File.read('/copy-file')).to eq("test\n")
    end

    context 'when +src+ is a directory' do
      it 'copies all its contents recursively' do
        described_class.mkdir('/test/dir')
        described_class.touch('/test/dir/file')

        described_class.cp_r('/test', '/dest')
        expect(File.exist?('/dest/dir/file')).to be true
      end
    end

    context 'when +dest+ is a directory' do
      it 'copies +src+ to +dest/src+' do
        described_class.mkdir(['/test/dir', '/dest'])
        described_class.touch('/test/dir/file')

        described_class.cp_r('/test', '/dest')
        expect(File.exist?('/dest/test/dir/file')).to be true
      end
    end

    context 'when +src+ is a list of files' do
      it 'copies each of them in +dest+' do
        described_class.mkdir(['/test/dir', '/test/dir2', '/dest'])
        described_class.touch(['/test/dir/file', '/test/dir2/file'])

        described_class.cp_r(['/test/dir', '/test/dir2'], '/dest')
        expect(File.exist?('/dest/dir2/file')).to be true
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

    it 'copies +src+ to +dest+' do
      described_class.install('/test-file', '/test-file2')
      expect(File.read('/test-file2')).to eq("test\n")
    end

    context 'when +:mode+ is set' do
      it 'changes the permission mode to +mode+' do
        expect(File).to receive(:chmod).with(0777, '/test-file2')
        described_class.install('/test-file', '/test-file2', mode: 0777)
      end
    end

    context 'when +src+ and +dest+ are the same file' do
      it 'raises an exception' do
        expect {
          described_class.install('/test-file', '/test-file')
        }.to raise_exception(ArgumentError)
      end
    end

    context 'when +dest+ already exists' do
      it 'removes destination before copy' do
        expect(File).to receive(:unlink).with('/test-file2')
        described_class.install('/test-file', '/test-file2')
      end

      context 'and +dest+ is a directory' do
        it 'installs +src+ in dest/src' do
          described_class.mkdir('/test-dir')
          described_class.install('/test-file', '/test-dir')
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

    it 'creates a hard link +dest+ which points to +src+' do
      described_class.ln('/test-file', '/test-file2')
      expect(File.read('/test-file2')).to eq(File.read('/test-file'))
    end

    it 'creates a hard link, not a symlink' do
      described_class.ln('/test-file', '/test-file2')
      expect(File.symlink?('/test-file2')).to be false
    end

    context 'when +dest+ already exists' do
      context 'and is a directory' do
        it 'creates a link dest/src' do
          described_class.mkdir('/test-dir')
          described_class.ln('/test-file', '/test-dir')
          expect(File.read('/test-dir/test-file')).to eq(File.read('/test-file'))
        end
      end

      context 'and it is not a directory' do
        it 'raises an exception' do
          described_class.touch('/test-file2')
          expect {
            described_class.ln('/test-file', '/test-file2')
          }.to raise_specific_error(SystemCallError)
        end

        context 'and +:force+ is set' do
          it 'overwrites +dest+' do
            described_class.touch('/test-file2')
            described_class.ln('/test-file', '/test-file2', force: true)
            expect(File.read('/test-file2')).to eq(File.read('/test-file'))
          end
        end
      end
    end

    context 'when passing a list of paths' do
      it 'creates a link for each path in +destdir+' do
        described_class.touch('/test-file2')
        described_class.mkdir('/test-dir')
        described_class.ln(['/test-file', '/test-file2'], '/test-dir')
      end

      context 'and +destdir+ is not a directory' do
        it 'raises an exception' do
          described_class.touch(['/test-file2', '/not-a-dir'])
          expect {
            described_class.ln(['/test-file', '/test-file2'], '/not-a-dir')
          }.to raise_specific_error(Errno::ENOTDIR)
        end
      end
    end
  end

  describe '.ln_s' do
    before :each do
      File.open('/test-file', 'w') { |f| f.puts 'test' }
      described_class.touch('/not-a-dir')
      described_class.mkdir('/test-dir')
    end

    it 'creates a symbolic link +new+' do
      described_class.ln_s('/test-file', '/test-link')
      expect(File.symlink?('/test-link')).to be true
    end

    it 'creates a symbolic link which points to +old+' do
      described_class.ln_s('/test-file', '/test-link')
      expect(File.read('/test-link')).to eq(File.read('/test-file'))
    end

    context 'when +new+ already exists' do
      context 'and it is a directory' do
        it 'creates a symbolic link +new/old+' do
          described_class.ln_s('/test-file', '/test-dir')
          expect(File.symlink?('/test-dir/test-file')).to be true
        end
      end

      context 'and it is not a directory' do
        it 'raises an exeption' do
          expect {
            described_class.ln_s('/test-file', '/not-a-dir')
          }.to raise_specific_error(Errno::EEXIST)
        end

        context 'and +:force+ is set' do
          it 'overwrites +new+' do
            described_class.ln_s('/test-file', '/not-a-dir', force: true)
            expect(File.symlink?('/not-a-dir')).to be true
          end
        end
      end
    end

    context 'when passing a list of paths' do
      before :each do
        File.open('/test-file2', 'w') { |f| f.puts 'test2' }
      end

      it 'creates several symbolic links in +destdir+' do
        described_class.ln_s(['/test-file', '/test-file2'], '/test-dir')
        expect(File.exist?('/test-dir/test-file2')).to be true
      end

      it 'creates symbolic links pointing to each item in the list' do
        described_class.ln_s(['/test-file', '/test-file2'], '/test-dir')
        expect(File.read('/test-dir/test-file2')).to eq(File.read('/test-file2'))
      end

      context 'when +destdir+ is not a directory' do
        it 'raises an error' do
          expect {
            described_class.ln_s(['/test-file', '/test-file2'], '/not-a-dir')
          }.to raise_specific_error(Errno::ENOTDIR)
        end
      end
    end
  end

  describe '.ln_sf' do
    it 'calls ln_s with +:force+ set to true' do
      File.open('/test-file', 'w') { |f| f.puts 'test' }
      File.open('/test-file2', 'w') { |f| f.puts 'test2' }
      described_class.ln_sf('/test-file', '/test-file2')
      expect(File.read('/test-file2')).to eq(File.read('/test-file'))
    end
  end

  describe '.makedirs' do
    it_behaves_like 'aliased method', :makedirs, :mkdir_p
  end

  describe '.mkdir' do
    it 'creates one directory' do
      described_class.mkdir('/test-dir')
      expect(File.directory?('/test-dir')).to be true
    end

    context 'when passing a list of paths' do
      it 'creates several directories' do
        described_class.mkdir(['/test-dir', '/test-dir2'])
        expect(File.directory?('/test-dir2')).to be true
      end
    end

    context 'when passing options' do
      context 'when passing mode parameter' do
        it 'creates directory with specified permissions' do
          described_class.mkdir('/test-dir', mode: 0654)
          expect(File.exist?('/test-dir')).to be true
          expect(File.stat('/test-dir').mode).to eq(0100654)
        end
      end

      context 'when passing noop parameter' do
        it 'does not create any directories' do
          described_class.mkdir(['/test-dir', '/another-dir'], noop: true)
          expect(File.directory?('/test-dir')).to be false
          expect(File.directory?('/another-dir')).to be false
        end
      end
    end


  end

  describe '.mkdir_p' do
    it 'creates a directory' do
      described_class.mkdir_p('/test-dir')
      expect(File.directory?('/test-dir')).to be true
    end

    it 'creates all the parent directories' do
      described_class.mkdir_p('/path/to/some/test-dir')
      expect(File.directory?('/path/to/some')).to be true
    end

    context 'when passing a list of paths' do
      it 'creates each directory' do
        described_class.mkdir_p(['/test-dir', '/test-dir'])
        expect(File.directory?('/test-dir')).to be true
      end

      it "creates each directory's parents" do
        described_class.mkdir_p(['/test-dir', '/path/to/some/test-dir'])
        expect(File.directory?('/path/to/some')).to be true
      end
    end

    context 'when passing options' do
      context 'when passing mode parameter' do
        it 'creates directory with specified permissions' do
          described_class.mkdir_p('/test-dir', mode: 0654)
          expect(File.exist?('/test-dir')).to be true
          expect(File.stat('/test-dir').mode).to eq(0100654)
        end
      end

      context 'when passing noop parameter' do
        it 'does not create any directories' do
          described_class.mkdir_p(['/test-dir', '/another-dir'], noop: true)
          expect(File.directory?('/test-dir')).to be false
          expect(File.directory?('/another-dir')).to be false
        end
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
    it 'moves +src+ to +dest+' do
      described_class.touch('/test-file')
      described_class.mv('/test-file', '/test-file2')
      expect(File.exist?('/test-file2')).to be true
    end

    it 'removes +src+' do
      described_class.touch('/test-file')
      described_class.mv('/test-file', '/test-file2')
      expect(File.exist?('/test-file')).to be false
    end

    context 'when +dest+ already exists' do
      context 'and is a directory' do
        it 'moves +src+ to dest/src' do
          described_class.touch('/test-file')
          described_class.mkdir('/test-dir')
          described_class.mv('/test-file', '/test-dir')
          expect(File.exist?('/test-dir/test-file')).to be true
        end
      end

      context 'and +dest+ is not a directory' do
        it 'it overwrites +dest+' do
          File.open('/test-file', 'w') { |f| f.puts 'test' }
          described_class.touch('/test-file2')
          described_class.mv('/test-file', '/test-file2')
          expect(File.read('/test-file2')).to eq("test\n")
        end
      end
    end
  end

  describe '.pwd' do
    it 'returns the name of the current directory' do
      described_class.cd '/test'
      expect(described_class.pwd).to eq('/test')
    end
  end

  describe '.remove' do
    it_behaves_like 'aliased method', :remove, :rm
  end

  describe '.remove_dir' do
    it 'removes the given directory +dir+' do
      described_class.mkdir('/test-dir')
      described_class.remove_dir('/test-dir')
      expect(File.exist?('/test-dir')).to be false
    end

    it 'removes the contents of the given directory +dir+' do
      described_class.mkdir_p('/test-dir/test-sub-dir')
      described_class.remove_dir('/test-dir')
      expect(File.exist?('/test-dir/test-sub-dir')).to be false
    end

    context 'when +force+ is set' do
      it 'ignores standard errors' do
        expect { described_class.remove_dir('/test-dir', true) }.not_to raise_error
      end
    end
  end

  describe '.remove_entry' do
    it 'removes a file system entry +path+' do
      described_class.touch('/test-file')
      described_class.remove_entry('/test-file')
      expect(File.exist?('/test-file')).to be false
    end

    context 'when +path+ is a directory' do
      it 'removes it recursively' do
        described_class.mkdir_p('/test-dir/test-sub-dir')
        described_class.remove_entry('/test-dir')
        expect(Dir.exist?('/test-dir')).to be false
      end
    end
  end

  describe '.remove_entry_secure' do
    before :each do
      described_class.mkdir_p('/test-dir/test-sub-dir')
    end

    it 'removes a file system entry +path+' do
      described_class.chmod(0755, '/')
      described_class.remove_entry_secure('/test-dir')
      expect(Dir.exist?('/test-dir')).to be false
    end

    context 'when +path+ is a directory' do
      it 'removes it recursively' do
        described_class.chmod(0755, '/')
        described_class.remove_entry_secure('/test-dir')
        expect(Dir.exist?('/test-dir/test-sub-dir')).to be false
      end

      context 'and is word writable' do
        it 'calls chown(2) on it' do
          described_class.chmod(01777, '/')
          directory = _fs.find('/test-dir')
          expect(directory).to receive(:uid=).at_least(:once)
          described_class.remove_entry_secure('/test-dir')
        end

        it 'calls chmod(2) on all sub directories' do
          described_class.chmod(01777, '/')
          directory = _fs.find('/test-dir')
          expect(directory).to receive(:mode=).at_least(:once)
          described_class.remove_entry_secure('/test-dir')
        end
      end
    end
  end

  describe '.remove_file' do
    it 'removes a file path' do
      described_class.touch('/test-file')
      described_class.remove_file('/test-file')
      expect(File.exist?('/test-file')).to be false
    end

    context 'when +force+ is set' do
      it 'ignores StandardError' do
        expect { described_class.remove_file('/no-file', true) }.not_to raise_error
      end
    end
  end

  describe '.rm' do
    it 'removes the specified file' do
      described_class.touch('/test-file')
      described_class.rm('/test-file')
      expect(File.exist?('/test-file')).to be false
    end

    it 'removes files specified in list' do
      described_class.touch(['/test-file', '/test-file2'])
      described_class.rm(['/test-file', '/test-file2'])
      expect(File.exist?('/test-file2')).to be false
    end

    it 'cannot remove a directory' do
      described_class.mkdir('/test-dir')
      expect { described_class.rm('/test-dir') }.to raise_specific_error(Errno::EPERM)
    end

    context 'when +:force+ is set' do
      it 'ignores StandardError' do
        described_class.mkdir('/test-dir')
        expect {
          described_class.rm('/test-dir', force: true)
        }.not_to raise_error
      end
    end
  end

  describe '.rm_f' do
    it 'calls rm with +:force+ set to true' do
      expect(described_class).to receive(:rm).with('test', force: true)
      described_class.rm_f('test')
    end
  end

  describe '.rm_r' do
    before :each do
      described_class.touch(['/test-file', '/test-file2'])
    end

    it 'removes a list of files' do
      described_class.rm_r(['/test-file', '/test-file2'])
      expect(File.exist?('/test-file2')).to be false
    end

    context 'when an item of the list is a directory' do
      it 'removes all its contents recursively' do
        described_class.mkdir('/test-dir')
        described_class.touch('/test-dir/test-file')
        described_class.rm_r(['/test-file', '/test-file2', '/test-dir'])
        expect(File.exist?('/test-dir/test-file')).to be false
      end
    end

    context 'when +:force+ is set' do
      it 'ignores StandardError' do
        expect {
          described_class.rm_r(['/no-file'], force: true)
        }.not_to raise_error
      end
    end
  end

  describe '.rm_rf' do
    it 'calls rm with +:force+ set to true' do
      expect(described_class).to receive(:rm_r).with('test', force: true)
      described_class.rm_rf('test')
    end
  end

  describe '.rmdir' do
    it 'Removes a directory' do
      described_class.mkdir('/test-dir')
      described_class.rmdir('/test-dir')
      expect(Dir.exist?('/test-dir')).to be false
    end

    it 'Removes a list of directories' do
      described_class.mkdir('/test-dir')
      described_class.mkdir('/test-dir2')
      described_class.rmdir(['/test-dir', '/test-dir2'])
      expect(Dir.exist?('/test-dir2')).to be false
    end

    context 'when a directory is not empty' do
      before :each do
        described_class.mkdir('/test-dir')
        described_class.touch('/test-dir/test-file')
      end

      it 'ignores errors' do
        expect { described_class.rmdir('/test-dir') }.not_to raise_error
      end

      it "doesn't remove the directory" do
        described_class.rmdir('/test-dir')
        expect(Dir.exist?('/test-dir')).to be true
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
      described_class.touch('/test-file')
      expect(_fs.find('/test-file')).not_to be_nil
    end

    it "creates a list of files if they don't exist" do
      described_class.touch(['/test-file', '/test-file2'])
      expect(_fs.find('/test-file2')).not_to be_nil
    end
  end

  describe '.uptodate?' do
    before :each do
      described_class.touch('/test-file')
      described_class.touch('/old-file')
      _fs.find!('/old-file').mtime = Time.now - 3600
    end

    it 'returns true if +newer+ is newer than all +old_list+' do
      expect(described_class.uptodate?('/test-file', ['/old-file'])).to be true
    end

    context 'when +newer+ does not exist' do
      it 'consideres it as older' do
        expect(described_class.uptodate?('/no-file', ['/old-file'])).to be false
      end
    end

    context 'when a item of +old_list+ does not exist' do
      it 'consideres it as older than +newer+' do
        uptodate = described_class.uptodate?('/test-file', ['/old-file', '/no-file'])
        expect(uptodate).to be true
      end
    end
  end
end
