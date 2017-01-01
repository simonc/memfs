require 'spec_helper'

module MemFs
  ::RSpec.describe File::Stat do
    let(:file_stat) { described_class.new('/test-file') }
    let(:dereferenced_file_stat) { described_class.new('/test-file', true) }

    let(:dir_link_stat) { described_class.new('/test-dir-link') }
    let(:dereferenced_dir_link_stat) { described_class.new('/test-dir-link', true) }

    let(:link_stat) { described_class.new('/test-link') }
    let(:dereferenced_link_stat) { described_class.new('/test-link', true) }

    let(:dir_stat) { described_class.new('/test-dir') }
    let(:dereferenced_dir_stat) { described_class.new('/test-dir', true) }

    let(:entry) { _fs.find!('/test-file') }

    before :each do
      _fs.mkdir('/test-dir')
      _fs.touch('/test-file')
      _fs.symlink('/test-file', '/test-link')
      _fs.symlink('/test-dir', '/test-dir-link')
      _fs.symlink('/no-file', '/test-no-file-link')
    end

    describe '.new' do
      context 'when optional dereference argument is set to true' do
        context 'when the last target of the link chain does not exist' do
          it 'raises an exception' do
            expect {
              described_class.new('/test-no-file-link', true)
            }.to raise_error(Errno::ENOENT)
          end
        end
      end
    end

    describe '#atime' do
      let(:time) { Time.now - 500_000 }

      it 'returns the access time of the entry' do
        entry = _fs.find!('/test-file')
        entry.atime = time
        expect(file_stat.atime).to eq(time)
      end

      context 'when the entry is a symlink' do
        context 'and the optional dereference argument is true' do
          it 'returns the access time of the last target of the link chain' do
            entry.atime = time
            expect(dereferenced_link_stat.atime).to eq(time)
          end
        end

        context 'and the optional dereference argument is false' do
          it 'returns the access time of the symlink itself' do
            entry.atime = time
            expect(link_stat.atime).not_to eq(time)
          end
        end
      end
    end

    describe '#blksize' do
      it 'returns the block size of the file' do
        expect(file_stat.blksize).to be(4096)
      end
    end

    describe '#blockdev?' do
      context 'when the file is a block device' do
        it 'returns true' do
          _fs.touch('/block-file')
          file = _fs.find('/block-file')
          file.block_device = true
          block_stat = described_class.new('/block-file')
          expect(block_stat.blockdev?).to be true
        end
      end

      context 'when the file is not a block device' do
        it 'returns false' do
          expect(file_stat.blockdev?).to be false
        end
      end
    end

    describe '#chardev?' do
      context 'when the file is a character device' do
        it 'returns true' do
          _fs.touch('/character-file')
          file = _fs.find('/character-file')
          file.character_device = true
          character_stat = described_class.new('/character-file')
          expect(character_stat.chardev?).to be true
        end
      end

      context 'when the file is not a character device' do
        it 'returns false' do
          expect(file_stat.chardev?).to be false
        end
      end
    end

    describe '#ctime' do
      let(:time) { Time.now - 500_000 }

      it 'returns the access time of the entry' do
        entry.ctime = time
        expect(file_stat.ctime).to eq(time)
      end

      context 'when the entry is a symlink' do
        context 'and the optional dereference argument is true' do
          it 'returns the access time of the last target of the link chain' do
            entry.ctime = time
            expect(dereferenced_link_stat.ctime).to eq(time)
          end
        end

        context 'and the optional dereference argument is false' do
          it 'returns the access time of the symlink itself' do
            entry.ctime = time
            expect(link_stat.ctime).not_to eq(time)
          end
        end
      end
    end

    describe '#dev' do
      it 'returns an integer representing the device on which stat resides' do
        expect(file_stat.dev).to be_a(Integer)
      end
    end

    describe '#directory?' do
      context 'when dereference is true' do
        context 'when the entry is a directory' do
          it 'returns true' do
            expect(dereferenced_dir_stat.directory?).to be true
          end
        end

        context 'when the entry is not a directory' do
          it 'returns false' do
            expect(dereferenced_file_stat.directory?).to be false
          end
        end

        context 'when the entry is a symlink' do
          context 'and the last target of the link chain is a directory' do
            it 'returns true' do
              expect(dereferenced_dir_link_stat.directory?).to be true
            end
          end

          context 'and the last target of the link chain is not a directory' do
            it 'returns false' do
              expect(dereferenced_link_stat.directory?).to be false
            end
          end
        end
      end

      context 'when dereference is false' do
        context 'when the entry is a directory' do
          it 'returns true' do
            expect(dir_stat.directory?).to be true
          end
        end

        context 'when the entry is not a directory' do
          it 'returns false' do
            expect(file_stat.directory?).to be false
          end
        end

        context 'when the entry is a symlink' do
          context 'and the last target of the link chain is a directory' do
            it 'returns false' do
              expect(dir_link_stat.directory?).to be false
            end
          end

          context 'and the last target of the link chain is not a directory' do
            it 'returns false' do
              expect(link_stat.directory?).to be false
            end
          end
        end
      end
    end

    describe '#entry' do
      it 'returns the comcerned entry' do
        expect(file_stat.entry).to be_a(Fake::File)
      end
    end

    describe '#executable?' do
      let(:access) { 0 }
      let(:gid) { 0 }
      let(:uid) { 0 }

      before :each do
        entry.mode = access
        entry.uid = uid
        entry.gid = gid
      end

      context 'when the file is not executable by anyone' do
        it 'return false' do
          expect(file_stat.executable?).to be false
        end
      end

      context 'when the file is user executable' do
        let(:access) { MemFs::Fake::Entry::UEXEC }

        context 'and the current user owns the file' do
          let(:uid) { Process.euid }

          it 'returns true' do
            expect(file_stat.executable?).to be true
          end
        end
      end

      context 'when the file is group executable' do
        let(:access) { MemFs::Fake::Entry::GEXEC }

        context 'and the current user is part of the owner group' do
          let(:gid) { Process.egid }

          it 'returns true' do
            expect(file_stat.executable?).to be true
          end
        end
      end

      context 'when the file is executable by anyone' do
        let(:access) { MemFs::Fake::Entry::OEXEC }

        context 'and the user has no specific right on it' do
          it 'returns true' do
            expect(file_stat.executable?).to be true
          end
        end
      end

      context 'when the file does not exist' do
        it 'returns false' do
          expect(file_stat.executable?).to be false
        end
      end
    end

    describe '#executable_real?' do
      let(:access) { 0 }
      let(:gid) { 0 }
      let(:uid) { 0 }

      before :each do
        entry.mode = access
        entry.uid = uid
        entry.gid = gid
      end

      context 'when the file is not executable by anyone' do
        it 'return false' do
          expect(file_stat.executable_real?).to be false
        end
      end

      context 'when the file is user executable' do
        let(:access) { MemFs::Fake::Entry::UEXEC }

        context 'and the current user owns the file' do
          let(:uid) { Process.uid }

          it 'returns true' do
            expect(file_stat.executable_real?).to be true
          end
        end
      end

      context 'when the file is group executable' do
        let(:access) { MemFs::Fake::Entry::GEXEC }

        context 'and the current user is part of the owner group' do
          let(:gid) { Process.gid }

          it 'returns true' do
            expect(file_stat.executable_real?).to be true
          end
        end
      end

      context 'when the file is executable by anyone' do
        let(:access) { MemFs::Fake::Entry::OEXEC }

        context 'and the user has no specific right on it' do
          it 'returns true' do
            expect(file_stat.executable_real?).to be true
          end
        end
      end

      context 'when the file does not exist' do
        it 'returns false' do
          expect(file_stat.executable_real?).to be false
        end
      end
    end

    describe '#file?' do
      context 'when dereference is true' do
        context 'when the entry is a regular file' do
          it 'returns true' do
            expect(dereferenced_file_stat.file?).to be true
          end
        end

        context 'when the entry is not a regular file' do
          it 'returns false' do
            expect(dereferenced_dir_stat.file?).to be false
          end
        end

        context 'when the entry is a symlink' do
          context 'and the last target of the link chain is a regular file' do
            it 'returns true' do
              expect(dereferenced_link_stat.file?).to be true
            end
          end

          context 'and the last target of the link chain is not a regular file' do
            it 'returns false' do
              expect(dereferenced_dir_link_stat.file?).to be false
            end
          end
        end
      end

      context 'when dereference is false' do
        context 'when the entry is a regular file' do
          it 'returns true' do
            expect(file_stat.file?).to be true
          end
        end

        context 'when the entry is not a regular file' do
          it 'returns false' do
            expect(dir_stat.file?).to be false
          end
        end

        context 'when the entry is a symlink' do
          context 'and the last target of the link chain is a regular file' do
            it 'returns false' do
              expect(link_stat.file?).to be false
            end
          end

          context 'and the last target of the link chain is not a regular file' do
            it 'returns false' do
              expect(dir_link_stat.file?).to be false
            end
          end
        end
      end
    end

    describe '#ftype' do
      context 'when the entry is a regular file' do
        it "returns 'file'" do
          expect(file_stat.ftype).to eq('file')
        end
      end

      context 'when the entry is a directory' do
        it "returns 'directory'" do
          expect(dir_stat.ftype).to eq('directory')
        end
      end

      context 'when the entry is a block device' do
        it "returns 'blockSpecial'" do
          _fs.touch('/block-file')
          file = _fs.find('/block-file')
          file.block_device = true
          block_stat = described_class.new('/block-file')
          expect(block_stat.ftype).to eq('blockSpecial')
        end
      end

      context 'when the entry is a character device' do
        it "returns 'characterSpecial'" do
          _fs.touch('/character-file')
          file = _fs.find('/character-file')
          file.character_device = true
          character_stat = described_class.new('/character-file')
          expect(character_stat.ftype).to eq('characterSpecial')
        end
      end

      context 'when the entry is a symlink' do
        it "returns 'link'" do
          expect(link_stat.ftype).to eq('link')
        end
      end

      # fifo and socket not handled for now

      context 'when the entry has no specific type' do
        it "returns 'unknown'" do
          root = _fs.find('/')
          root.add_entry Fake::Entry.new('test-entry')
          entry_stat = described_class.new('/test-entry')
          expect(entry_stat.ftype).to eq('unknown')
        end
      end
    end

    describe '#gid' do
      it 'returns the group id of the named entry' do
        _fs.chown(nil, 42, '/test-file')
        expect(file_stat.gid).to be(42)
      end
    end

    describe '#grpowned?' do
      context 'when the effective user group owns of the file' do
        it 'returns true' do
          _fs.chown(0, Process.egid, '/test-file')
          expect(file_stat.grpowned?).to be true
        end
      end

      context 'when the effective user group does not own of the file' do
        it 'returns false' do
          _fs.chown(0, 0, '/test-file')
          expect(file_stat.grpowned?).to be false
        end
      end
    end

    describe '#ino' do
      it 'returns the inode number for stat.' do
        expect(file_stat.ino).to be_a(Integer)
      end
    end

    describe '#mode' do
      it 'returns an integer representing the permission bits of stat' do
        _fs.chmod(0777, '/test-file')
        expect(file_stat.mode).to be(0100777)
      end
    end

    describe '#owned?' do
      context 'when the effective user owns of the file' do
        it 'returns true' do
          _fs.chown(Process.euid, 0, '/test-file')
          expect(file_stat.owned?).to be true
        end
      end

      context 'when the effective user does not own of the file' do
        it 'returns false' do
          _fs.chown(0, 0, '/test-file')
          expect(file_stat.owned?).to be false
        end
      end
    end

    describe '#pipe?' do
      # Pipes are not handled for now

      context 'when the file is not a pipe' do
        it 'returns false' do
          expect(file_stat.pipe?).to be false
        end
      end
    end

    describe '#readable?' do
      let(:access) { 0 }
      let(:gid) { 0 }
      let(:uid) { 0 }

      before :each do
        entry.mode = access
        entry.uid = uid
        entry.gid = gid
      end

      context 'when the file is not readable by anyone' do
        it 'return false' do
          expect(file_stat.readable?).to be false
        end
      end

      context 'when the file is user readable' do
        let(:access) { MemFs::Fake::Entry::UREAD }

        context 'and the current user owns the file' do
          let(:uid) { Process.euid }

          it 'returns true' do
            expect(file_stat.readable?).to be true
          end
        end
      end

      context 'when the file is group readable' do
        let(:access) { MemFs::Fake::Entry::GREAD }

        context 'and the current user is part of the owner group' do
          let(:gid) { Process.egid }

          it 'returns true' do
            expect(file_stat.readable?).to be true
          end
        end
      end

      context 'when the file is readable by anyone' do
        let(:access) { MemFs::Fake::Entry::OREAD }

        context 'and the user has no specific right on it' do
          it 'returns true' do
            expect(file_stat.readable?).to be true
          end
        end
      end
    end

    describe '#readable_real?' do
      let(:access) { 0 }
      let(:gid) { 0 }
      let(:uid) { 0 }

      before :each do
        entry.mode = access
        entry.uid = uid
        entry.gid = gid
      end

      context 'when the file is not readable by anyone' do
        it 'return false' do
          expect(file_stat.readable_real?).to be false
        end
      end

      context 'when the file is user readable' do
        let(:access) { MemFs::Fake::Entry::UREAD }

        context 'and the current user owns the file' do
          let(:uid) { Process.euid }

          it 'returns true' do
            expect(file_stat.readable_real?).to be true
          end
        end
      end

      context 'when the file is group readable' do
        let(:access) { MemFs::Fake::Entry::GREAD }

        context 'and the current user is part of the owner group' do
          let(:gid) { Process.egid }

          it 'returns true' do
            expect(file_stat.readable_real?).to be true
          end
        end
      end

      context 'when the file is readable by anyone' do
        let(:access) { MemFs::Fake::Entry::OREAD }

        context 'and the user has no specific right on it' do
          it 'returns true' do
            expect(file_stat.readable_real?).to be true
          end
        end
      end

      context 'when the file does not exist' do
        it 'returns false' do
          expect(file_stat.readable_real?).to be false
        end
      end
    end

    describe '#setgid?' do
      context 'when the file has the setgid bit set' do
        it 'returns true' do
          _fs.chmod(02000, '/test-file')
          expect(file_stat.setgid?).to be true
        end
      end

      context 'when the file does not have the setgid bit set' do
        it 'returns false' do
          _fs.chmod(0644, '/test-file')
          expect(file_stat.setgid?).to be false
        end
      end
    end

    describe '#setuid?' do
      context 'when the file has the setuid bit set' do
        it 'returns true' do
          _fs.chmod(04000, '/test-file')
          expect(file_stat.setuid?).to be true
        end
      end

      context 'when the file does not have the setuid bit set' do
        it 'returns false' do
          _fs.chmod(0644, '/test-file')
          expect(file_stat.setuid?).to be false
        end
      end
    end

    describe '#socket?' do
      # Sockets are not handled for now

      context 'when the file is not a socket' do
        it 'returns false' do
          expect(file_stat.socket?).to be false
        end
      end
    end

    describe '#sticky?' do
      it 'returns true if the named file has the sticky bit set' do
        _fs.chmod(01777, '/test-file')
        expect(file_stat.sticky?).to be true
      end

      it "returns false if the named file hasn't' the sticky bit set" do
        _fs.chmod(0666, '/test-file')
        expect(file_stat.sticky?).to be false
      end
    end

    describe '#symlink?' do
      context 'when dereference is true' do
        context 'when the entry is a symlink' do
          it 'returns false' do
            expect(dereferenced_link_stat.symlink?).to be false
          end
        end

        context 'when the entry is not a symlink' do
          it 'returns false' do
            expect(dereferenced_file_stat.symlink?).to be false
          end
        end
      end

      context 'when dereference is false' do
        context 'when the entry is a symlink' do
          it 'returns true' do
            expect(link_stat.symlink?).to be true
          end
        end

        context 'when the entry is not a symlink' do
          it 'returns false' do
            expect(file_stat.symlink?).to be false
          end
        end
      end
    end

    describe '#uid' do
      it 'returns the user id of the named entry' do
        _fs.chown(42, nil, '/test-file')
        expect(file_stat.uid).to be(42)
      end
    end

    describe '#world_reable?' do
      context 'when +file_name+ is readable by others' do
        it 'returns an integer representing the file permission bits of +file_name+' do
          _fs.chmod(MemFs::Fake::Entry::OREAD, '/test-file')
          expect(file_stat.world_readable?).to eq(MemFs::Fake::Entry::OREAD)
        end
      end

      context 'when +file_name+ is not readable by others' do
        it 'returns nil' do
          _fs.chmod(MemFs::Fake::Entry::UREAD, '/test-file')
          expect(file_stat.world_readable?).to be_nil
        end
      end
    end

    describe '#world_writable?' do
      context 'when +file_name+ is writable by others' do
        it 'returns an integer representing the file permission bits of +file_name+' do
          _fs.chmod(MemFs::Fake::Entry::OWRITE, '/test-file')
          expect(file_stat.world_writable?).to eq(MemFs::Fake::Entry::OWRITE)
        end
      end

      context 'when +file_name+ is not writable by others' do
        it 'returns nil' do
          _fs.chmod(MemFs::Fake::Entry::UWRITE, '/test-file')
          expect(file_stat.world_writable?).to be_nil
        end
      end
    end

    describe '#writable?' do
      let(:access) { 0 }
      let(:gid) { 0 }
      let(:uid) { 0 }

      before :each do
        entry.mode = access
        entry.uid = uid
        entry.gid = gid
      end

      context 'when the file is not executable by anyone' do
        it 'return false' do
          expect(file_stat.writable?).to be false
        end
      end

      context 'when the file is user executable' do
        let(:access) { MemFs::Fake::Entry::UWRITE }

        context 'and the current user owns the file' do
          let(:uid) { Process.euid }

          it 'returns true' do
            expect(file_stat.writable?).to be true
          end
        end
      end

      context 'when the file is group executable' do
        let(:access) { MemFs::Fake::Entry::GWRITE }

        context 'and the current user is part of the owner group' do
          let(:gid) { Process.egid }

          it 'returns true' do
            expect(file_stat.writable?).to be true
          end
        end
      end

      context 'when the file is executable by anyone' do
        let(:access) { MemFs::Fake::Entry::OWRITE }

        context 'and the user has no specific right on it' do
          it 'returns true' do
            expect(file_stat.writable?).to be true
          end
        end
      end

      context 'when the file does not exist' do
        it 'returns false' do
          expect(file_stat.writable?).to be false
        end
      end
    end

    describe '#writable_real?' do
      let(:access) { 0 }
      let(:gid) { 0 }
      let(:uid) { 0 }

      before :each do
        entry.mode = access
        entry.uid = uid
        entry.gid = gid
      end

      context 'when the file is not executable by anyone' do
        it 'return false' do
          expect(file_stat.writable_real?).to be false
        end
      end

      context 'when the file is user executable' do
        let(:access) { MemFs::Fake::Entry::UWRITE }

        context 'and the current user owns the file' do
          let(:uid) { Process.euid }

          it 'returns true' do
            expect(file_stat.writable_real?).to be true
          end
        end
      end

      context 'when the file is group executable' do
        let(:access) { MemFs::Fake::Entry::GWRITE }

        context 'and the current user is part of the owner group' do
          let(:gid) { Process.egid }

          it 'returns true' do
            expect(file_stat.writable_real?).to be true
          end
        end
      end

      context 'when the file is executable by anyone' do
        let(:access) { MemFs::Fake::Entry::OWRITE }

        context 'and the user has no specific right on it' do
          it 'returns true' do
            expect(file_stat.writable_real?).to be true
          end
        end
      end

      context 'when the file does not exist' do
        it 'returns false' do
          expect(file_stat.writable_real?).to be false
        end
      end
    end

    describe '#zero?' do
      context 'when the file has a zero size' do
        it 'returns true' do
          expect(file_stat.zero?).to be true
        end
      end

      context 'when the file does not have a zero size' do
        before :each do
          _fs.find!('/test-file').content << 'test'
        end

        it 'returns false' do
          expect(file_stat.zero?).to be false
        end
      end
    end
  end
end
