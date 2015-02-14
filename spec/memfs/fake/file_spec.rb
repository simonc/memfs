require 'spec_helper'

module MemFs
  module Fake
    describe File do
      let(:file) { _fs.find!('/test-file') }

      before do
        _fs.touch('/test-file')
      end

      it 'stores the modification made on its content' do
        file.content << 'test'
        expect(_fs.find!('/test-file').content.to_s).to eq('test')
      end

      describe '#close' do
        it 'sets the file as closed?' do
          file.close
          expect(file).to be_closed
        end
      end

      describe '#content' do
        it 'returns the file content' do
          expect(file.content).not_to be_nil
        end

        context 'when the file is empty' do
          it 'returns an empty string container' do
            expect(file.content.to_s).to be_empty
          end
        end
      end

      describe '#type' do
        context 'when the file is a regular file' do
          it "returns 'file'" do
            expect(file.type).to eq('file')
          end
        end

        context 'when the file is a block device' do
          it "returns 'blockSpecial'" do
            file.block_device = true
            expect(file.type).to eq('blockSpecial')
          end
        end

        context 'when the file is a character device' do
          it "returns 'characterSpecial'" do
            file.character_device = true
            expect(file.type).to eq('characterSpecial')
          end
        end
      end
    end
  end
end
