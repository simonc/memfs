require 'spec_helper'

module MemFs
  module Fake
    describe File do
      let(:file) { fs.find!('/test-file') }

      before do
        fs.touch('/test-file')
      end

      it "stores the modification made on its content" do
        file.content << 'test'
        expect(fs.find!('/test-file').content.to_s).to eq('test')
      end

      describe "#content" do
        it "returns the file content" do
          expect(file.content).not_to be_nil
        end

        context "when the file is empty" do
          it "returns an empty string container" do
            expect(file.content.to_s).to be_empty
          end
        end
      end

      describe "#close" do
        it "sets the file as closed?" do
          file.close
          expect(file).to be_closed
        end
      end
    end
  end
end
