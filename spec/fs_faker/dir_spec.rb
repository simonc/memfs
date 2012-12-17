require 'spec_helper'

module FsFaker
  describe Dir do
    let(:fs) { FsFaker::FileSystem.instance }

    before :each do
      Dir.mkdir '/'
      Dir.mkdir '/test'
    end

    describe '.chdir' do
      it "changes the current working directory" do
        Dir.chdir '/test'
        Dir.getwd.should == '/test'
      end

      it "returns zero" do
        Dir.chdir('/test').should be_zero
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
          Dir.mkdir '/'
          Dir.chdir '/'
          previous_dir = Dir.pwd
          Dir.chdir('/test') {}
          Dir.pwd.should == previous_dir
        end
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
        File.directory?('/new-folder').should be_true
      end
    end

    describe '.entries' do
      it "returns an array containing all of the filenames in the given directory" do
        %w[/test /test/dir1 /test/dir2].each { |dir| Dir.mkdir dir }
        fs.touch '/test/file1', '/test/file2'
        Dir.entries('/test').should == %w[. .. dir1 dir2 file1 file2]
      end
    end
  end
end
