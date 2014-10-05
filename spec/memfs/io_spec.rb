require 'spec_helper'

module MemFs
  describe IO do
    before :each do
      fs.mkdir '/test-dir'
      fs.touch '/test-file'
    end

    describe 'Class Methods' do
      subject { MemFs::IO }

      let(:io) { subject.new('/test-file') }

      describe 'Delegated Methods' do
        it 'delegates .copy_stream' do
          expect(subject).to respond_to(:copy_stream)
        end
      end

      describe '.new' do
        context 'when the mode is provided' do
          context 'and it is an integer' do
            it 'sets the mode to the integer value' do
              file = subject.new('/test-file', File::RDWR)
              expect(file.send(:opening_mode)).to eq(File::RDWR)
            end
          end

          context 'and it is a string' do
            it 'sets the mode to the integer value' do
              file = subject.new('/test-file', 'r+')
              expect(file.send(:opening_mode)).to eq(File::RDWR)
            end
          end

          context 'and it specifies that the file must be created' do
            context 'and the file already exists' do
              it 'changes the mtime of the file' do
                expect(fs).to receive(:touch).with('/test-file')
                subject.new('/test-file', 'w')
              end
            end
          end

          context 'and it specifies that the file must be truncated' do
            context 'and the file already exists' do
              it 'truncates its content' do
                subject.open('/test-file', 'w') { |f| f.puts 'hello' }
                file = subject.new('/test-file', 'w')
                file.close
                expect(subject.read('/test-file')).to eq ''
              end
            end
          end
        end

        context 'when no argument is given' do
          it 'raises an exception' do
            expect { subject.new }.to raise_error(ArgumentError)
          end
        end

        context 'when too many arguments are given' do
          it 'raises an exception' do
            expect { subject.new(1, 2, 3, 4) }.to raise_error(ArgumentError)
          end
        end
      end

      describe '.read' do
        before :each do
          subject.open('/test-file', 'w') { |f| f.puts 'test' }
        end

        it 'reads the content of the given file' do
          expect(subject.read('/test-file')).to eq("test\n")
        end

        context 'when +lenght+ is provided' do
          it 'reads only +length+ characters' do
            expect(subject.read('/test-file', 2)).to eq('te')
          end

          context 'when +length+ is bigger than the file size' do
            it 'reads until the end of the file' do
              expect(subject.read('/test-file', 1000)).to eq("test\n")
            end
          end
        end

        context 'when +offset+ is provided' do
          it 'starts reading from the offset' do
            expect(subject.read('/test-file', 2, 1)).to eq('es')
          end

          it 'raises an error if offset is negative' do
            expect {
              subject.read('/test-file', 2, -1)
            }.to raise_error(Errno::EINVAL)
          end
        end

        context 'when the last argument is a hash' do
          it 'passes the contained options to +open+' do
            expect(subject).to receive(:open)
                .with('/test-file', File::RDONLY, encoding: 'UTF-8')
                .and_return(io)
            subject.read('/test-file', encoding: 'UTF-8')
          end

          context 'when it contains the +open_args+ key' do
            it 'takes precedence over the other options' do
              expect(subject).to receive(:open)
                  .with('/test-file', 'r')
                  .and_return(io)
              subject.read('/test-file', mode: 'w', open_args: ['r'])
            end
          end
        end
      end
    end

    describe 'Instance Methods' do
      subject { MemFs::IO.open('/test-file') }

      let(:random_string) { ('a'..'z').to_a.sample(10).join }
      let(:write_subject) { MemFs::IO.open('/test-file', 'w') }

      describe '#close' do
        it 'closes the file stream' do
          subject.close
          expect(subject).to be_closed
        end
      end

      describe '#closed?' do
        it 'returns true when the file is closed' do
          subject.close
          expect(subject.closed?).to be true
        end

        it 'returns false when the file is open' do
          expect(subject.closed?).to be false
        end
      end

      describe '#each' do
        let(:lines) do
          ["Hello this is a file\n",
           "with some lines\n",
           "for test purpose\n"]
        end

        before do
          MemFs::IO.open('/test-file', 'w') do |f|
            lines.each { |line| f.puts line }
          end
        end

        it 'executes the block for every line in the file' do
          expect { |blk| subject.each(&blk) }.to \
            yield_successive_args(*lines)
        end

        it 'returns the file itself' do
          expect(subject.each {}).to be subject
        end

        context 'when a separator is given' do
          it 'uses this separator to split lines' do
            expected_lines = [
              'Hello this is a f',
              "ile\nwith some lines\nf",
              "or test purpose\n"
            ]
            expect { |blk| subject.each('f', &blk) }.to \
              yield_successive_args(*expected_lines)
          end
        end

        context 'when the file is not open for reading' do
          it 'raises an exception' do
            expect { write_subject.each { |l| puts l } }.to raise_error(IOError)
          end

          context 'when no block is given' do
            it 'does not raise an exception' do
              expect { write_subject.each }.not_to raise_error
            end
          end
        end

        context 'when no block is given' do
          it 'returns an enumerator' do
            expect(subject.each.next).to eq "Hello this is a file\n"
          end
        end
      end

      describe '#external_encoding' do
        it 'returns the Encoding object representing the file encoding' do
          expect(subject.external_encoding).to be_an(Encoding)
        end

        context 'when the file is open in write mode' do
          context 'and no encoding has been specified' do
            it 'returns nil' do
              expect(write_subject.external_encoding).to be nil
            end
          end

          context 'and an encoding has been specified' do
            subject { MemFs::IO.open('/test-file', 'w', external_encoding: 'UTF-8') }

            it 'returns the Encoding' do
              expect(subject.external_encoding).to be_an(Encoding)
            end
          end
        end
      end

      describe '#pos' do
        before :each do
          MemFs::IO.open('/test-file', 'w') { |f| f.puts 'test' }
        end

        it 'returns zero when the file was just opened' do
          expect(subject.pos).to be_zero
        end

        it 'returns the reading offset when some of the file has been read' do
          subject.read(2)
          expect(subject.pos).to eq(2)
        end
      end

      describe '#puts' do
        it 'appends content to the file' do
          write_subject.puts 'test'
          write_subject.close
          expect(write_subject.send(:content).to_s).to eq("test\n")
        end

        it "does not override the file's content" do
          write_subject.puts 'test'
          write_subject.puts 'test'
          write_subject.close
          expect(write_subject.send(:content).to_s).to eq("test\ntest\n")
        end

        it 'raises an exception if the file is not writable' do
          expect { subject.puts 'test' }.to raise_error(IOError)
        end
      end

      describe '#read' do
        before :each do
          MemFs::IO.open('/test-file', 'w') { |f| f.puts random_string }
        end

        context 'when no length is given' do
          it 'returns the content of the named file' do
            expect(subject.read).to eq(random_string + "\n")
          end

          it 'returns an empty string if called a second time' do
            subject.read
            expect(subject.read).to be_empty
          end
        end

        context 'when a length is given' do
          it 'returns a string of the given length' do
            expect(subject.read(2)).to eq(random_string[0, 2])
          end

          it 'returns nil when there is nothing more to read' do
            subject.read(1000)
            expect(subject.read(1000)).to be_nil
          end
        end

        context 'when a buffer is given' do
          it 'fills the buffer with the read content' do
            buffer = String.new
            subject.read(2, buffer)
            expect(buffer).to eq(random_string[0, 2])
          end
        end
      end

      describe '#seek' do
        before :each do
          MemFs::IO.open('/test-file', 'w') { |f| f.puts 'test' }
        end

        it 'returns zero' do
          expect(subject.seek(1)).to eq(0)
        end

        context 'when +whence+ is not provided' do
          it 'seeks to the absolute location given by +amount+' do
            subject.seek(3)
            expect(subject.pos).to eq(3)
          end
        end

        context 'when +whence+ is IO::SEEK_CUR' do
          it 'seeks to +amount+ plus current position' do
            subject.read(1)
            subject.seek(1, IO::SEEK_CUR)
            expect(subject.pos).to eq(2)
          end
        end

        context 'when +whence+ is IO::SEEK_END' do
          it 'seeks to +amount+ plus end of stream' do
            subject.seek(-1, IO::SEEK_END)
            expect(subject.pos).to eq(4)
          end
        end

        context 'when +whence+ is IO::SEEK_SET' do
          it 'seeks to the absolute location given by +amount+' do
            subject.seek(3, IO::SEEK_SET)
            expect(subject.pos).to eq(3)
          end
        end

        context 'when +whence+ is invalid' do
          it 'raises an exception' do
            expect { subject.seek(0, 42) }.to raise_error(Errno::EINVAL)
          end
        end

        context 'if the position ends up to be less than zero' do
          it 'raises an exception' do
            expect { subject.seek(-1) }.to raise_error(Errno::EINVAL)
          end
        end
      end

      describe '#stat' do
        it 'returns the +Stat+ object of the file' do
          expect(subject.stat).to be_a(File::Stat)
        end
      end

      describe '#write' do
        it 'writes the given string to file' do
          write_subject.write 'test'
          expect(MemFs::IO.read('/test-file')).to eq('test')
        end

        it 'returns the number of bytes written' do
          expect(write_subject.write('test')).to eq(4)
        end

        context 'when the file is not opened for writing' do
          it 'raises an exception' do
            expect { subject.write('test') }.to raise_error(IOError)
          end
        end

        context 'when the argument is not a string' do
          it 'will be converted to a string using to_s' do
            write_subject.write 42
            expect(MemFs::IO.read('/test-file')).to eq('42')
          end
        end
      end
    end
  end
end
