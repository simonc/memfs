require 'spec_helper'

module FsFaker
  describe FileSystem do
    let(:fs) { FileSystem.instance }

    context "with the /test directory created" do
      before :each do
        fs.clear!
        fs.mkdir '/test'
      end

      describe '.getwd' do
        it "returns the current working directory" do
          fs.chdir '/test'
          fs.getwd.should == '/test'
        end

        it "has a pwd alias" do
          fs.method(:pwd).should == fs.method(:getwd)
        end
      end

      describe '.chdir' do
        it "changes the current working directory" do
          fs.chdir '/test'
          fs.getwd.should == '/test'
        end

        it "raises an error if directory does not exist" do
          expect { fs.chdir('/nowhere') }.to raise_error(Errno::ENOENT)
        end

        context "when a block is given" do
          it "changes current working directory for the block" do
            fs.chdir '/test' do
              fs.getwd.should == '/test'
            end
          end

          it "gets back to previous directory once the block is finished" do
            fs.mkdir '/'
            fs.chdir '/'
            previous_dir = fs.getwd
            fs.chdir('/test') {}
            fs.getwd.should == previous_dir
          end
        end
      end

      describe '.find!' do
        it "finds the entry if it exists" do
          fs.find!('/test').name.should == 'test'
        end

        it "raises an error if path does not exist" do
          expect { fs.find!('/nowhere') }.to raise_error(Errno::ENOENT)
        end
      end

      describe '.directory?' do
        it "returns true if an entry is a directory" do
          fs.directory?('/test').should be_true
        end

        it "returns false if an entry is not a directory" do
          fs.touch('/some-file')
          fs.directory?('/some-file').should be_false
        end
      end
    end

    describe '.mkdir' do
      it "creates a directory" do
        fs.mkdir '/test'
        fs.registred_entries['/test'].should be_a(Fake::Directory)
      end
    end

    describe '.clear!' do
      it "clear the registred entries" do
        fs.mkdir '/test'
        fs.clear!
        fs.registred_entries.should be_empty
      end
    end

    describe '.touch' do
      it "creates a regular file" do
        fs.touch '/some-file'
        fs.registred_entries['/some-file'].should be_a(Fake::File)
      end
    end

    describe '.chmod' do
      it "changes permission bits on the named file" do
        fs.touch('/some-file')
        fs.chmod(777, '/some-file')
        fs.find!('/some-file').mode.should be(777)
      end
    end
  end
end
