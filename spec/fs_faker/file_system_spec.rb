require 'spec_helper'

module FsFaker
  describe FileSystem do
    let(:fs) { FileSystem.instance }

    describe '#new' do
      it "creates the root directory" do
        fs.find!('/').should be(fs.root)
      end
    end

    context "with the /test directory created" do
      before :each do
        fs.mkdir '/test'
      end

      describe '#getwd' do
        it "returns the current working directory" do
          fs.chdir '/test'
          fs.getwd.should == '/test'
        end

        it "has a pwd alias" do
          fs.method(:pwd).should == fs.method(:getwd)
        end
      end

      describe '#chdir' do
        it "changes the current working directory" do
          fs.chdir '/test'
          fs.getwd.should == '/test'
        end

        it "raises an error if directory does not exist" do
          expect { fs.chdir('/nowhere') }.to raise_error(Errno::ENOENT)
        end

        it "raises an error if the destination is not a directory" do
          fs.touch('/test-file')
          expect { fs.chdir('/test-file') }.to raise_error(Errno::ENOTDIR)
        end

        context "when a block is given" do
          it "changes current working directory for the block" do
            location = nil
            fs.chdir '/test' do
              location = fs.getwd
            end
            location.should == '/test'
          end

          it "gets back to previous directory once the block is finished" do
            fs.mkdir '/'
            fs.chdir '/'
            previous_dir = fs.getwd
            fs.chdir('/test') {}
            fs.getwd.should == previous_dir
          end
        end

        context "when the destination is a symlink" do
          it "sets current directory as the last link chain target" do
            fs.mkdir '/test'
            fs.symlink('/test', '/test-link')
            fs.chdir('/test-link')
            fs.getwd.should == '/test'
          end
        end
      end

      describe '#find' do
        it "finds the entry if it exists" do
          fs.find('/test').name.should == 'test'
        end

        it "doesn't raise an error if path does not exist" do
          expect { fs.find('/nowhere') }.not_to raise_error(Errno::ENOENT)
        end
      end

      describe '#find!' do
        it "finds the entry if it exists" do
          fs.find!('/test').name.should == 'test'
        end

        it "raises an error if path does not exist" do
          expect { fs.find!('/nowhere') }.to raise_error(Errno::ENOENT)
        end
      end

      describe '#directory?' do
        it "returns true if an entry is a directory" do
          fs.directory?('/test').should be_true
        end

        it "returns false if an entry is not a directory" do
          fs.touch('/some-file')
          fs.directory?('/some-file').should be_false
        end
      end

      describe '#find_directory!' do
        it "returns the named directory" do
          fs.find_directory!('/test').should be_a(Fake::Directory)
        end

        it "raises an error if the named entry is not a directory" do
          fs.touch '/test-file'
          expect { fs.find_directory!('/test-file') }.to raise_error(Errno::ENOTDIR)
        end
      end
    end

    describe '#mkdir' do
      it "creates a directory" do
        fs.mkdir '/test'
        fs.find!('/test').should be_a(Fake::Directory)
      end

      context "when a relative path is given" do
        it "creates a directory in current directory" do
          fs.mkdir '/test'
          fs.chdir '/test'
          fs.mkdir 'test-dir'
          fs.find!('/test/test-dir').should be_a(Fake::Directory)
        end
      end
    end

    describe '#clear!' do
      it "clear the registred entries" do
        fs.mkdir '/test'
        fs.clear!
        fs.root.entry_names.should == %w[. ..]
      end
    end

    describe '#touch' do
      it "creates a regular file" do
        fs.touch '/some-file'
        fs.find!('/some-file').should be_a(Fake::File)
      end

      it "creates a regular file for each named filed" do
        fs.touch '/some-file', '/some-file2'
        fs.find!('/some-file2').should be_a(Fake::File)
      end

      it "creates an entry only if it doesn't exist" do
        fs.touch '/some-file'
        FsFaker::Fake::File.should_not_receive(:new)
        fs.touch '/some-file'
      end

      context "when the named file already exists" do
        let(:time) { Time.now - 5000 }
        before :each do
          fs.touch '/some-file'
          file = fs.find!('/some-file')
          file.atime = file.mtime = time
        end

        it "sets the access time of the touched file" do
          fs.touch '/some-file'
          fs.find!('/some-file').atime.should_not == time
        end

        it "sets the modification time of the touched file" do
          fs.touch '/some-file'
          fs.find!('/some-file').atime.should_not == time
        end
      end
    end

    describe '#chmod' do
      it "changes permission bits on the named file" do
        fs.touch('/some-file')
        fs.chmod(0777, '/some-file')
        fs.find!('/some-file').mode.should be(0100777)
      end

      context "when the named file is a symlink" do
        it "changes the permission bits on the symlink itself" do
          fs.touch('/some-file')
          fs.symlink('/some-file', '/some-link')
          fs.chmod(0777, '/some-link')
          fs.find!('/some-link').mode.should be(0100777)
        end
      end
    end

    describe '#symlink' do
      it "creates a symbolic link" do
        fs.symlink('/some-file', '/some-link')
        fs.find!('/some-link').should be_a(Fake::Symlink)
      end
    end

    describe '#symlink?' do
      it "returns true if the entry is a symlink" do
        fs.symlink('/test-file', '/test-link')
        fs.symlink?('/test-link').should be_true
      end

      it "returns false if the entry is not a symlink" do
        fs.touch('/test-file')
        fs.symlink?('/test-file').should be_false
      end

      it "returns false if the entry doesn't exist" do
        fs.symlink?('/test-file').should be_false
      end
    end

    describe '#entries' do
      it "returns an array containing all of the filenames in the given directory" do
        %w[/test /test/dir1 /test/dir2].each { |dir| fs.mkdir dir }
        fs.touch '/test/file1', '/test/file2'
        fs.entries('/test').should == %w[. .. dir1 dir2 file1 file2]
      end
    end

    describe '#find_parent!' do
      it "returns the parent directory of the named entry" do
        fs.mkdir '/test'
        fs.find_parent!('/test/test-file').should be_a(Fake::Directory)
      end

      it "raises an error if the parent directory does not exist" do
        expect { fs.find_parent!('/nowhere/test-file') }.to raise_error(Errno::ENOENT)
      end

      it "raises an error if the parent is not a directory" do
        fs.touch('/test-file')
        expect { fs.find_parent!('/test-file/test') }.to raise_error(Errno::ENOTDIR)
      end
    end

    describe "#chown" do
      before :each do
        fs.touch '/test-file'
      end

      it "changes the owner of the named file to the given numeric owner id" do
        fs.chown(42, nil, '/test-file')
        fs.find!('/test-file').uid.should be(42)
      end

      it "changes the group of the named file to the given numeric group id" do
        fs.chown(nil, 42, '/test-file')
        fs.find!('/test-file').gid.should be(42)
      end

      it "ignores nil user id" do
        previous_uid = fs.find!('/test-file').uid

        fs.chown(nil, 42, '/test-file')
        fs.find!('/test-file').uid.should == previous_uid
      end

      it "ignores nil group id" do
        previous_gid = fs.find!('/test-file').gid

        fs.chown(42, nil, '/test-file')
        fs.find!('/test-file').gid.should == previous_gid
      end

      it "ignores -1 user id" do
        previous_uid = fs.find!('/test-file').uid

        fs.chown(-1, 42, '/test-file')
        fs.find!('/test-file').uid.should == previous_uid
      end

      it "ignores -1 group id" do
        previous_gid = fs.find!('/test-file').gid

        fs.chown(42, -1, '/test-file')
        fs.find!('/test-file').gid.should == previous_gid
      end

      context "when the named entry is a symlink" do
        before :each do
          fs.symlink '/test-file', '/test-link'
        end

        it "changes the owner on the last target of the link chain" do
          fs.chown(42, nil, '/test-link')
          fs.find!('/test-file').uid.should be(42)
        end

        it "changes the group on the last target of the link chain" do
          fs.chown(nil, 42, '/test-link')
          fs.find!('/test-file').gid.should be(42)
        end

        it "doesn't change the owner of the symlink" do
          fs.chown(42, nil, '/test-link')
          fs.find!('/test-link').uid.should_not be(42)
        end

        it "doesn't change the group of the symlink" do
          fs.chown(nil, 42, '/test-link')
          fs.find!('/test-link').gid.should_not be(42)
        end
      end
    end
  end
end
