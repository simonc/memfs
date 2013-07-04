require 'spec_helper'

module MemFs
  describe Dir do
    before :each do
      Dir.mkdir '/test'
    end

    describe '.chdir' do
      it "changes the current working directory" do
        Dir.chdir '/test'
        Dir.getwd.should == '/test'
      end

      it "returns zero" do
        expect(Dir.chdir('/test')).to be_zero
      end

      it "raises an error when the folder does not exist" do
        expect { Dir.chdir('/nowhere') }.to raise_error(Errno::ENOENT)
      end

      context "when a block is given" do
        it "changes current working directory for the block" do
          Dir.chdir '/test' do
            Dir.pwd.should == '/test'
          end
        end
    
        it "gets back to previous directory once the block is finished" do
          Dir.chdir '/'
          previous_dir = Dir.pwd
          Dir.chdir('/test') {}
          Dir.pwd.should == previous_dir
        end
      end
    end

    describe '.entries' do
      it "returns an array containing all of the filenames in the given directory" do
        %w[/test/dir1 /test/dir2].each { |dir| Dir.mkdir dir }
        fs.touch '/test/file1', '/test/file2'
        Dir.entries('/test').should == %w[. .. dir1 dir2 file1 file2]
      end
    end

    describe ".exists?" do
      it "returns true if the given +path+ exists and is a directory" do
        Dir.mkdir('/test-dir')
        expect(Dir.exists?('/test-dir')).to be_true
      end

      it "returns false if the given +path+ does not exist" do
        Dir.exists?('/test-dir')
        expect(Dir.exists?('/test-dir')).to be_false
      end

      it "returns false if the given +path+ is not a directory" do
        fs.touch('/test-file')
        expect(Dir.exists?('/test-file')).to be_false
      end
    end

    describe '.getwd' do
      it "returns the path to the current working directory" do
        Dir.getwd.should == FileSystem.instance.getwd
      end

      it "has a pwd alias" do
        Dir.method(:pwd).should == Dir.method(:getwd)
      end
    end

    describe '.mkdir' do
      it "creates a directory" do
        Dir.mkdir '/new-folder'
        expect(File.directory?('/new-folder')).to be_true
      end

      context "when the directory already exist" do
        it "raises an exception" do
          expect { Dir.mkdir('/') }.to raise_error(Errno::EEXIST)
        end
      end
    end

    describe ".rmdir" do
      it "deletes the named directory" do
        Dir.mkdir('/test-dir')
        Dir.rmdir('/test-dir')
        expect(Dir.exists?('/test-dir')).to be_false
      end

      context "when the directory is not empty" do
        it "raises an exception" do
          Dir.mkdir('/test-dir')
          Dir.mkdir('/test-dir/test-sub-dir')
          expect { Dir.rmdir('/test-dir') }.to raise_error(Errno::ENOTEMPTY)
        end
      end
    end
  end
end
