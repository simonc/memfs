require 'spec_helper'

module MemFs
  describe Dir do
    subject { MemFs::Dir }

    before :each do
      subject.mkdir '/test'
    end

    describe '.chdir' do
      it "changes the current working directory" do
        subject.chdir '/test'
        expect(subject.getwd).to eq('/test')
      end

      it "returns zero" do
        expect(subject.chdir('/test')).to be_zero
      end

      it "raises an error when the folder does not exist" do
        expect { subject.chdir('/nowhere') }.to raise_error(Errno::ENOENT)
      end

      context "when a block is given" do
        it "changes current working directory for the block" do
          subject.chdir '/test' do
            expect(subject.pwd).to eq('/test')
          end
        end
    
        it "gets back to previous directory once the block is finished" do
          subject.chdir '/'
          previous_dir = subject.pwd
          subject.chdir('/test') {}
          expect(subject.pwd).to eq(previous_dir)
        end
      end
    end

    describe ".delete" do
      it_behaves_like 'aliased method', :delete, :rmdir
    end

    describe '.entries' do
      it "returns an array containing all of the filenames in the given directory" do
        %w[/test/dir1 /test/dir2].each { |dir| subject.mkdir dir }
        fs.touch '/test/file1', '/test/file2'
        expect(subject.entries('/test')).to eq(%w[. .. dir1 dir2 file1 file2])
      end
    end

    describe ".exists?" do
      it "returns true if the given +path+ exists and is a directory" do
        subject.mkdir('/test-dir')
        expect(subject.exists?('/test-dir')).to be_true
      end

      it "returns false if the given +path+ does not exist" do
        expect(subject.exists?('/test-dir')).to be_false
      end

      it "returns false if the given +path+ is not a directory" do
        fs.touch('/test-file')
        expect(subject.exists?('/test-file')).to be_false
      end
    end

    describe '.getwd' do
      it "returns the path to the current working directory" do
        expect(subject.getwd).to eq(FileSystem.instance.getwd)
      end
    end

    describe '.mkdir' do
      it "creates a directory" do
        subject.mkdir '/new-folder'
        expect(File.directory?('/new-folder')).to be_true
      end

      context "when the directory already exist" do
        it "raises an exception" do
          expect { subject.mkdir('/') }.to raise_error(Errno::EEXIST)
        end
      end
    end

    describe ".pwd" do
      it_behaves_like 'aliased method', :pwd, :getwd
    end

    describe ".rmdir" do
      it "deletes the named directory" do
        subject.mkdir('/test-dir')
        subject.rmdir('/test-dir')
        expect(subject.exists?('/test-dir')).to be_false
      end

      context "when the directory is not empty" do
        it "raises an exception" do
          subject.mkdir('/test-dir')
          subject.mkdir('/test-dir/test-sub-dir')
          expect { subject.rmdir('/test-dir') }.to raise_error(Errno::ENOTEMPTY)
        end
      end
    end
  end
end
