require 'spec_helper'

module FsFaker
  describe File do
    let(:fs) { FileSystem.instance }

    describe '.chmod' do
      it "changes permission bits on the named file" do
        fs.touch '/some-file'
        File.chmod(777, '/some-file')
        fs.find!('/some-file').mode.should be(777)
      end
    end

    describe '.directory?' do
      it "returns true if an entry is a directory" do
        fs.mkdir('/test')
        File.directory?('/test').should be_true
      end
    end

    describe '.path' do
      it "returns the string representation of the path" do
        File.path('/some/test').should == '/some/test'
      end

      it "returns the string representation of the path of a Pathname" do
        File.path(Pathname.new('/some/test')).should == '/some/test'
      end
    end
  end
end
