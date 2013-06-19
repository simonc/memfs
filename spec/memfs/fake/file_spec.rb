require 'spec_helper'

module MemFs
  module Fake
    describe File do
      let(:file) { fs.find!('/test-file') }

      before do
        fs.touch('/test-file')
      end

      it "stores the modification made on its content" do
        file.content << "test"
        fs.find!('/test-file').content.to_s.should == "test"
      end

      describe "#content" do
        it "returns the file content" do
          file.content.should_not be_nil
        end

        it "returns an empty string container if the file is empty" do
          file.content.to_s.should == ""
        end
      end

      describe "#close" do
        it "sets the file as closed?" do
          file.close
          file.should be_closed
        end
      end
    end
  end
end
