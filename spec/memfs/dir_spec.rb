require 'spec_helper'

module MemFs
  describe Dir do
    subject { described_class.new('/test') }

    before { described_class.mkdir '/test' }

    it 'is Enumerable' do
      expect(subject).to be_an(Enumerable)
    end

    describe '[]' do
      context 'when a string is given' do
        it 'acts like calling glob' do
          expect(described_class['/*']).to eq %w[/tmp /test]
        end
      end

      context 'when a list of strings is given' do
        it 'acts like calling glob' do
          expect(described_class['/tm*', '/te*']).to eq %w[/tmp /test]
        end
      end
    end

    describe '.chdir' do
      it 'changes the current working directory' do
        described_class.chdir '/test'
        expect(described_class.getwd).to eq('/test')
      end

      it 'returns zero' do
        expect(described_class.chdir('/test')).to be_zero
      end

      it 'raises an error when the folder does not exist' do
        expect { described_class.chdir('/nowhere') }.to raise_error(Errno::ENOENT)
      end

      context 'when a block is given' do
        it 'changes current working directory for the block' do
          described_class.chdir '/test' do
            expect(described_class.pwd).to eq('/test')
          end
        end

        it 'gets back to previous directory once the block is finished' do
          described_class.chdir '/'
          expect {
            described_class.chdir('/test') {}
          }.to_not change { described_class.pwd }
        end
      end
    end

    describe '.chroot' do
      before { allow(Process).to receive_messages(uid: 0) }

      it "changes the process's idea of the file system root" do

        described_class.mkdir('/test/subdir')
        described_class.chroot('/test')

        expect(File.exist?('/subdir')).to be true
      end

      it 'returns zero' do
        expect(described_class.chroot('/test')).to eq 0
      end

      context 'when the given path is a file' do
        before { _fs.touch('/test/test-file') }

        it 'raises an exception' do
          expect { described_class.chroot('/test/test-file') }.to raise_error(Errno::ENOTDIR)
        end
      end

      context "when the given path doesn't exist" do
        it 'raises an exception' do
          expect { described_class.chroot('/no-dir') }.to raise_error(Errno::ENOENT)
        end
      end

      context 'when the user is not root' do
        before { allow(Process).to receive_messages(uid: 42) }

        it 'raises an exception' do
          expect { described_class.chroot('/no-dir') }.to raise_error(Errno::EPERM)
        end
      end
    end

    describe '.delete' do
      subject { described_class }
      it_behaves_like 'aliased method', :delete, :rmdir
    end

    describe '.entries' do
      it 'returns an array containing all of the filenames in the given directory' do
        %w[/test/dir1 /test/dir2].each { |dir| described_class.mkdir dir }
        _fs.touch '/test/file1', '/test/file2'
        expect(described_class.entries('/test')).to eq(%w[. .. dir1 dir2 file1 file2])
      end
    end

    describe '.exist?' do
      subject { described_class }
      it_behaves_like 'aliased method', :exist?, :exists?
    end

    describe '.exists?' do
      it 'returns true if the given +path+ exists and is a directory' do
        described_class.mkdir('/test-dir')
        expect(described_class.exists?('/test-dir')).to be true
      end

      it 'returns false if the given +path+ does not exist' do
        expect(described_class.exists?('/test-dir')).to be false
      end

      it 'returns false if the given +path+ is not a directory' do
        _fs.touch('/test-file')
        expect(described_class.exists?('/test-file')).to be false
      end
    end

    describe '.foreach' do
      before :each do
        _fs.touch('/test/test-file', '/test/test-file2')
      end

      context 'when a block is given' do
        it 'calls the block once for each entry in the named directory' do
          expect { |blk|
            described_class.foreach('/test', &blk)
          }.to yield_control.exactly(4).times
        end

        it 'passes each entry as a parameter to the block' do
          expect { |blk|
            described_class.foreach('/test', &blk)
          }.to yield_successive_args('.', '..', 'test-file', 'test-file2')
        end

        context "and the directory doesn't exist" do
          it 'raises an exception' do
            expect { described_class.foreach('/no-dir') {} }.to raise_error
          end
        end

        context 'and the given path is not a directory' do
          it 'raises an exception' do
            expect {
              described_class.foreach('/test/test-file') {}
            }.to raise_error
          end
        end
      end

      context 'when no block is given' do
        it 'returns an enumerator' do
          list = described_class.foreach('/test-dir')
          expect(list).to be_an(Enumerator)
        end

        context "and the directory doesn't exist" do
          it 'returns an enumerator' do
            list = described_class.foreach('/no-dir')
            expect(list).to be_an(Enumerator)
          end
        end

        context 'and the given path is not a directory' do
          it 'returns an enumerator' do
            list = described_class.foreach('/test-dir/test-file')
            expect(list).to be_an(Enumerator)
          end
        end
      end
    end

    describe '.getwd' do
      it 'returns the path to the current working directory' do
        expect(described_class.getwd).to eq(FileSystem.instance.getwd)
      end
    end

    describe '.glob' do
      before do
        _fs.clear!
        3.times do |dirnum|
          _fs.mkdir "/test#{dirnum}"
          _fs.mkdir "/test#{dirnum}/subdir"
          3.times do |filenum|
            _fs.touch "/test#{dirnum}/subdir/file#{filenum}"
          end
        end
      end

      shared_examples 'returning matching filenames' do |pattern, filenames|
        it "with #{pattern}" do
          expect(described_class.glob(pattern)).to eq filenames
        end
      end

      it_behaves_like 'returning matching filenames', '/', %w[/]
      it_behaves_like 'returning matching filenames', '/test0', %w[/test0]
      it_behaves_like 'returning matching filenames', '/*', %w[/tmp /test0 /test1 /test2]
      it_behaves_like 'returning matching filenames', '/test*', %w[/test0 /test1 /test2]
      it_behaves_like 'returning matching filenames', '/*0', %w[/test0]
      it_behaves_like 'returning matching filenames', '/*es*', %w[/test0 /test1 /test2]
      it_behaves_like 'returning matching filenames', '/**/file0', %w[/test0/subdir/file0 /test1/subdir/file0 /test2/subdir/file0]
      it_behaves_like 'returning matching filenames', '/test?', %w[/test0 /test1 /test2]
      it_behaves_like 'returning matching filenames', '/test[01]', %w[/test0 /test1]
      it_behaves_like 'returning matching filenames', '/test[^2]', %w[/test0 /test1]

      if defined?(File::FNM_EXTGLOB)
        it_behaves_like 'returning matching filenames', '/test{1,2}', %w[/test1 /test2]
      end

      context 'when a flag is given' do
        it 'uses it to compare filenames' do
          expect(described_class.glob('/TEST*', File::FNM_CASEFOLD)).to eq \
            %w[/test0 /test1 /test2]
        end
      end

      context 'when a block is given' do
        it 'calls the block with every matching filenames' do
          expect { |blk| described_class.glob('/test*', &blk) }.to \
            yield_successive_args('/test0', '/test1', '/test2')
        end

        it 'returns nil' do
          expect(described_class.glob('/*') {}).to be nil
        end
      end

      context 'when pattern is an array of patterns' do
        it 'returns the list of files matching any pattern' do
          expect(described_class.glob(['/*0', '/*1'])).to eq %w[/test0 /test1]
        end
      end
    end

    describe '.home' do
      it 'returns the home directory of the current user' do
        expect(described_class.home).to eq ENV['HOME']
      end

      context 'when a username is given' do
        it 'returns the home directory of the given user' do
          home_dir = described_class.home(ENV['USER'])
          expect(home_dir).to eq ENV['HOME']
        end
      end
    end

    describe '.mkdir' do
      it 'creates a directory' do
        described_class.mkdir '/new-folder'
        expect(File.directory?('/new-folder')).to be true
      end

      it 'sets directory permissions to default 0777' do
        described_class.mkdir '/new-folder'
        expect(File.stat('/new-folder').mode).to eq(0100777)
      end

      context 'when permissions are specified' do
        it 'sets directory permissions to specified value' do
          described_class.mkdir '/new-folder', 0644
          expect(File.stat('/new-folder').mode).to eq(0100644)
        end
      end

      context 'when the directory already exist' do
        it 'raises an exception' do
          expect { described_class.mkdir('/') }.to raise_error(Errno::EEXIST)
        end
      end
    end

    describe '.open' do
      context 'when no block is given' do
        it 'returns the opened directory' do
          expect(described_class.open('/test')).to be_a(Dir)
        end
      end

      context 'when a block is given' do
        it 'calls the block with the opened directory as argument' do
          expect { |blk| described_class.open('/test', &blk) }.to yield_with_args(Dir)
        end

        it 'returns nil' do
          expect(described_class.open('/test') {}).to be_nil
        end

        it 'ensures the directory is closed' do
          dir = nil
          described_class.open('/test') { |d| dir = d }
          expect { dir.close }.to raise_error(IOError)
        end
      end

      context "when the given directory doesn't exist" do
        it 'raises an exception' do
          expect { described_class.open('/no-dir') }.to raise_error
        end
      end

      context 'when the given path is not a directory' do
        before { _fs.touch('/test/test-file') }

        it 'raises an exception' do
          expect { described_class.open('/test/test-file') }.to raise_error
        end
      end
    end

    describe '.new' do
      context "when the given directory doesn't exist" do
        it 'raises an exception' do
          expect { described_class.new('/no-dir') }.to raise_error
        end
      end

      context 'when the given path is not a directory' do
        before { _fs.touch('/test/test-file') }

        it 'raises an exception' do
          expect { described_class.new('/test/test-file') }.to raise_error
        end
      end
    end

    describe '.pwd' do
      subject { described_class }
      it_behaves_like 'aliased method', :pwd, :getwd
    end

    describe '.rmdir' do
      it 'deletes the named directory' do
        described_class.mkdir('/test-dir')
        described_class.rmdir('/test-dir')
        expect(described_class.exists?('/test-dir')).to be false
      end

      context 'when the directory is not empty' do
        it 'raises an exception' do
          described_class.mkdir('/test-dir')
          described_class.mkdir('/test-dir/test-sub-dir')
          expect { described_class.rmdir('/test-dir') }.to raise_error(Errno::ENOTEMPTY)
        end
      end
    end

    describe '.tmpdir' do
      it 'returns /tmp' do
        expect(described_class.tmpdir).to eq '/tmp'
      end
    end

    describe '.unlink' do
      subject { described_class }
      it_behaves_like 'aliased method', :unlink, :rmdir
    end

    describe '#close' do
      it 'closes the directory' do
        dir = described_class.open('/test')
        dir.close
        expect { dir.close }.to raise_error(IOError)
      end
    end

    describe '#each' do
      before { _fs.touch('/test/test-file', '/test/test-file2') }

      it 'calls the block once for each entry in this directory' do
        expect { |blk| subject.each(&blk) }.to yield_control.exactly(4).times
      end

      it 'passes the filename of each entry as a parameter to the block' do
        expect { |blk|
          subject.each(&blk)
        }.to yield_successive_args('.', '..', 'test-file', 'test-file2')
      end

      context 'when no block is given' do
        it 'returns an enumerator' do
          expect(subject.each).to be_an(Enumerator)
        end
      end
    end

    describe '#path' do
      it "returns the path parameter passed to dir's constructor" do
        expect(subject.path).to eq '/test'
      end
    end

    describe '#pos' do
      it 'returns the current position in dir' do
        3.times { subject.read }
        expect(subject.pos).to eq 3
      end
    end

    describe '#pos=' do
      before { 3.times { subject.read } }

      it 'seeks to a particular location in dir' do
        subject.pos = 1
        expect(subject.pos).to eq 1
      end

      it 'returns the given position' do
        expect(subject.pos = 2).to eq 2
      end

      context 'when the location has not been seeked yet' do
        it "doesn't change the location" do
          subject.pos = 42
          expect(subject.pos).to eq 3
        end
      end

      context 'when the location is negative' do
        it "doesn't change the location" do
          subject.pos = -1
          expect(subject.pos).to eq 3
        end
      end
    end

    describe '#read' do
      before do
        _fs.touch('/test/a')
        _fs.touch('/test/b')
      end

      it 'reads the next entry from dir and returns it' do
        expect(subject.read).to eq '.'
      end

      context 'when calling several times' do
        it 'returns the next entry each time' do
          2.times { subject.read }
          expect(subject.read).to eq 'a'
        end
      end

      context 'when there are no entries left' do
        it 'returns nil' do
          4.times { subject.read }
          expect(subject.read).to be_nil
        end
      end
    end

    describe '#rewind' do
      it 'repositions dir to the first entry' do
        3.times { subject.read }
        subject.rewind
        expect(subject.read).to eq '.'
      end

      it 'returns the dir itself' do
        expect(subject.rewind).to be subject
      end
    end

    describe '#seek' do
      before { 3.times { subject.read } }

      it 'seeks to a particular location in dir' do
        subject.seek(1)
        expect(subject.pos).to eq 1
      end

      it 'returns the dir itself' do
        expect(subject.seek(2)).to be subject
      end

      context 'when the location has not been seeked yet' do
        it "doesn't change the location" do
          subject.seek(42)
          expect(subject.pos).to eq 3
        end
      end

      context 'when the location is negative' do
        it "doesn't change the location" do
          subject.seek(-1)
          expect(subject.pos).to eq 3
        end
      end
    end

    describe '#tell' do
      it 'returns the current position in dir' do
        3.times { subject.read }
        expect(subject.tell).to eq 3
      end
    end

    describe '#to_path' do
      it "returns the path parameter passed to dir's constructor" do
        expect(subject.to_path).to eq '/test'
      end
    end
  end
end
