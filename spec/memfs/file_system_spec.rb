require 'spec_helper'

module MemFs
  describe FileSystem do
    subject { _fs }

    before :each do
      subject.mkdir '/test-dir'
    end

    describe '#chdir' do
      it 'changes the current working directory' do
        subject.chdir '/test-dir'
        expect(subject.getwd).to eq('/test-dir')
      end

      it 'raises an error if directory does not exist' do
        expect { subject.chdir('/nowhere') }.to raise_error(Errno::ENOENT)
      end

      it 'raises an error if the destination is not a directory' do
        subject.touch('/test-file')
        expect { subject.chdir('/test-file') }.to raise_error(Errno::ENOTDIR)
      end

      context 'when a block is given' do
        it 'changes current working directory for the block' do
          location = nil
          subject.chdir '/test-dir' do
            location = subject.getwd
          end
          expect(location).to eq('/test-dir')
        end

        it 'gets back to previous directory once the block is finished' do
          subject.chdir '/'
          expect {
            subject.chdir('/test-dir') {}
          }.to_not change { subject.getwd }
        end
      end

      context 'when the destination is a symlink' do
        it 'sets current directory as the last link chain target' do
          subject.symlink('/test-dir', '/test-link')
          subject.chdir('/test-link')
          expect(subject.getwd).to eq('/test-dir')
        end
      end
    end

    describe '#chmod' do
      it 'changes permission bits on the named file' do
        subject.touch('/some-file')
        subject.chmod(0777, '/some-file')
        expect(subject.find!('/some-file').mode).to be(0100777)
      end

      context 'when the named file is a symlink' do
        it 'changes the permission bits on the symlink itself' do
          subject.touch('/some-file')
          subject.symlink('/some-file', '/some-link')
          subject.chmod(0777, '/some-link')
          expect(subject.find!('/some-link').mode).to be(0100777)
        end
      end
    end

    describe '#chown' do
      before :each do
        subject.touch '/test-file'
      end

      it 'changes the owner of the named file to the given numeric owner id' do
        subject.chown(42, nil, '/test-file')
        expect(subject.find!('/test-file').uid).to be(42)
      end

      it 'changes the group of the named file to the given numeric group id' do
        subject.chown(nil, 42, '/test-file')
        expect(subject.find!('/test-file').gid).to be(42)
      end

      it 'ignores nil user id' do
        expect {
          subject.chown(nil, 42, '/test-file')
        }.to_not change { subject.find!('/test-file').uid }
      end

      it 'ignores nil group id' do
        expect {
          subject.chown(42, nil, '/test-file')
        }.to_not change { subject.find!('/test-file').gid }
      end

      it 'ignores -1 user id' do
        expect {
          subject.chown(-1, 42, '/test-file')
        }.to_not change { subject.find!('/test-file').uid }
      end

      it 'ignores -1 group id' do
        expect {
          subject.chown(42, -1, '/test-file')
        }.to_not change { subject.find!('/test-file').gid }
      end

      context 'when the named entry is a symlink' do
        before :each do
          subject.symlink '/test-file', '/test-link'
        end

        it 'changes the owner on the last target of the link chain' do
          subject.chown(42, nil, '/test-link')
          expect(subject.find!('/test-file').uid).to be(42)
        end

        it 'changes the group on the last target of the link chain' do
          subject.chown(nil, 42, '/test-link')
          expect(subject.find!('/test-file').gid).to be(42)
        end

        it "doesn't change the owner of the symlink" do
          subject.chown(42, nil, '/test-link')
          expect(subject.find!('/test-link').uid).not_to eq(42)
        end

        it "doesn't change the group of the symlink" do
          subject.chown(nil, 42, '/test-link')
          expect(subject.find!('/test-link').gid).not_to eq(42)
        end
      end
    end

    describe '#clear!' do
      it 'clear the registred entries' do
        subject.clear!
        expect(subject.root.entry_names).to eq(%w[. .. tmp])
      end

      it 'sets the current directory to /' do
        subject.clear!
        expect(subject.getwd).to eq('/')
      end
    end

    describe '#entries' do
      it 'returns an array containing all of the filenames in the given directory' do
        %w[/test-dir/new-dir /test-dir/new-dir2].each { |dir| subject.mkdir dir }
        subject.touch '/test-dir/test-file', '/test-dir/test-file2'
        expect(subject.entries('/test-dir')).to eq(%w[. .. new-dir new-dir2 test-file test-file2])
      end
    end

    describe '#find' do
      context 'when the entry for the given path exists' do
        it 'returns the entry' do
          entry = subject.find('/test-dir')
          expect(entry).not_to be_nil
        end
      end

      context 'when there is no entry for the given path' do
        it 'returns nil' do
          entry = subject.find('/no-file')
          expect(entry).to be_nil
        end
      end

      context 'when a part of the given path is a symlink' do
        before :each do
          subject.symlink('/test-dir', '/test-dir-link')
          subject.symlink('/no-dir', '/test-no-link')
          subject.touch('/test-dir/test-file')
        end

        context "and the symlink's target exists" do
          it 'returns the entry' do
            entry = subject.find('/test-dir-link/test-file')
            expect(entry).not_to be_nil
          end
        end

        context "and the symlink's target does not exist" do
          it 'returns nil' do
            entry = subject.find('/test-no-link/test-file')
            expect(entry).to be_nil
          end
        end
      end
    end

    describe '#find!' do
      context 'when the entry for the given path exists' do
        it 'returns the entry' do
          entry = subject.find!('/test-dir')
          expect(entry).not_to be_nil
        end
      end

      context 'when there is no entry for the given path' do
        it 'raises an exception' do
          expect { subject.find!('/no-file') }.to raise_exception
        end
      end

      context 'when a part of the given path is a symlink' do
        before :each do
          _fs.symlink('/test-dir', '/test-dir-link')
          _fs.touch('/test-dir/test-file')
        end

        context "and the symlink's target exists" do
          it 'returns the entry' do
            entry = subject.find!('/test-dir-link/test-file')
            expect(entry).not_to be_nil
          end
        end

        context "and the symlink's target does not exist" do
          it 'raises an exception' do
            expect {
              subject.find!('/test-no-link/test-file')
            }.to raise_error
          end
        end
      end
    end

    describe '#find_directory!' do
      it 'returns the named directory' do
        expect(subject.find_directory!('/test-dir')).to be_a(Fake::Directory)
      end

      it 'raises an error if the named entry is not a directory' do
        subject.touch '/test-file'
        expect { subject.find_directory!('/test-file') }.to raise_error(Errno::ENOTDIR)
      end
    end

    describe '#find_parent!' do
      it 'returns the parent directory of the named entry' do
        expect(subject.find_parent!('/test-dir/test-file')).to be_a(Fake::Directory)
      end

      it 'raises an error if the parent directory does not exist' do
        expect { subject.find_parent!('/no-dir/test-file') }.to raise_error(Errno::ENOENT)
      end

      it 'raises an error if the parent is not a directory' do
        subject.touch('/test-file')
        expect { subject.find_parent!('/test-file/test') }.to raise_error(Errno::ENOTDIR)
      end
    end

    describe '#getwd' do
      it 'returns the current working directory' do
        subject.chdir '/test-dir'
        expect(subject.getwd).to eq('/test-dir')
      end
    end

    describe '#link' do
      before :each do
        subject.touch('/some-file')
      end

      it 'creates a hard link +dest+ that points to +src+' do
        subject.link('/some-file', '/some-link')
        expect(subject.find!('/some-link').content).to be(subject.find!('/some-file').content)
      end

      it 'does not create a symbolic link' do
        subject.link('/some-file', '/some-link')
        expect(subject.find!('/some-link')).not_to be_a(Fake::Symlink)
      end

      context 'when +new_name+ already exists' do
        it 'raises an exception' do
          subject.touch('/some-link')
          expect { subject.link('/some-file', '/some-link') }.to raise_error(SystemCallError)
        end
      end
    end

    describe '#mkdir' do
      it 'creates a directory' do
        subject.mkdir '/new-dir'
        expect(subject.find!('/new-dir')).to be_a(Fake::Directory)
      end

      it 'sets directory permissions to default 0777' do
        subject.mkdir '/new-dir'
        expect(subject.find!('/new-dir').mode).to eq(0100777)
      end

      context 'when permissions are specified' do
        it 'sets directory permission to specified value' do
          subject.mkdir '/new-dir', 0644
          expect(subject.find!('/new-dir').mode).to eq(0100644)
        end
      end

      context 'when a relative path is given' do
        it 'creates a directory in current directory' do
          subject.chdir '/test-dir'
          subject.mkdir 'new-dir'
          expect(subject.find!('/test-dir/new-dir')).to be_a(Fake::Directory)
        end
      end

      context 'when the directory already exists' do
        it 'raises an exception' do
          expect { subject.mkdir('/') }.to raise_error(Errno::EEXIST)
        end
      end
    end

    describe '#new' do
      it 'creates the root directory' do
        expect(subject.find!('/')).to be(subject.root)
      end
    end

    describe '#paths' do
      before do
        subject.mkdir('/test-dir/subdir')
        subject.touch('/test-dir/subdir/file1', '/test-dir/subdir/file2')
      end

      it 'returns the list of all the existing paths' do
        expect(subject.paths).to eq \
          %w[/ /tmp /test-dir /test-dir/subdir /test-dir/subdir/file1 /test-dir/subdir/file2]
      end
    end

    describe '#pwd' do
      it_behaves_like 'aliased method', :pwd, :getwd
    end

    describe '#rename' do
      it 'renames the given file to the new name' do
        subject.touch('/test-file')
        subject.rename('/test-file', '/test-file2')
        expect(subject.find('/test-file2')).not_to be_nil
      end

      it 'removes the old file' do
        subject.touch('/test-file')
        subject.rename('/test-file', '/test-file2')
        expect(subject.find('/test-file')).to be_nil
      end

      it 'can move a file in another directory' do
        subject.touch('/test-file')
        subject.rename('/test-file', '/test-dir/test-file')
        expect(subject.find('/test-dir/test-file')).not_to be_nil
      end
    end

    describe '#rmdir' do
      it 'removes the given directory' do
        subject.rmdir('/test-dir')
        expect(subject.find('/test-dir')).to be_nil
      end

      context 'when the directory is not empty' do
        it 'raises an exception' do
          subject.mkdir('/test-dir/test-sub-dir')
          expect { subject.rmdir('/test-dir') }.to raise_error(Errno::ENOTEMPTY)
        end
      end
    end

    describe '#symlink' do
      it 'creates a symbolic link' do
        subject.symlink('/some-file', '/some-link')
        expect(subject.find!('/some-link')).to be_a(Fake::Symlink)
      end

      context 'when +new_name+ already exists' do
        it 'raises an exception' do
          subject.touch('/some-file')
          subject.touch('/some-file2')
          expect { subject.symlink('/some-file', '/some-file2') }.to raise_error(Errno::EEXIST)
        end
      end
    end

    describe '#touch' do
      it 'creates a regular file' do
        subject.touch '/some-file'
        expect(subject.find!('/some-file')).to be_a(Fake::File)
      end

      it 'creates a regular file for each named filed' do
        subject.touch '/some-file', '/some-file2'
        expect(subject.find!('/some-file2')).to be_a(Fake::File)
      end

      it "creates an entry only if it doesn't exist" do
        subject.touch '/some-file'
        expect(MemFs::Fake::File).not_to receive(:new)
        subject.touch '/some-file'
      end

      context 'when the named file already exists' do
        let(:time) { Time.now - 5000 }
        before :each do
          subject.touch '/some-file'
          file = subject.find!('/some-file')
          file.atime = file.mtime = time
        end

        it 'sets the access time of the touched file' do
          subject.touch '/some-file'
          expect(subject.find!('/some-file').atime).not_to eq(time)
        end

        it 'sets the modification time of the touched file' do
          subject.touch '/some-file'
          expect(subject.find!('/some-file').atime).not_to eq(time)
        end
      end
    end

    describe '#unlink' do
      it 'deletes the named file' do
        subject.touch('/some-file')
        subject.unlink('/some-file')
        expect(subject.find('/some-file')).to be_nil
      end

      context 'when the entry is a directory' do
        it 'raises an exception' do
          expect { subject.unlink('/test-dir') }.to raise_error
        end
      end
    end
  end
end
