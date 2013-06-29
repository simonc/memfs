require 'spec_helper'

module MemFs
  module Fake

    describe File::Content do
      subject { File::Content.new }

      describe "#<<" do
        it "writes the given string to the contained string" do
          subject << 'test'
          expect(subject.to_s).to eq('test')
        end
      end

      describe "#initialize" do
        context "when no argument is given" do
          it "initialize the contained string to an empty one" do
            expect(subject.to_s).to eq('')
          end
        end

        context "when an argument is given" do
          subject { File::Content.new(base_value) }

          context "when the argument is a string" do
            let(:base_value) { 'test' }

            it "initialize the contained string with the given one" do
              expect(subject.to_s).to eq('test')
            end

            it "duplicates the original string to prevent modifications on it" do
              expect(subject.to_s).not_to be(base_value)
            end
          end

          context "when the argument is not a string" do
            let(:base_value) { 42 }

            it "converts it to a string" do
              expect(subject.to_s).to eq('42')
            end
          end
        end
      end

      describe "#puts" do
        it "appends the given string to the contained string" do
          subject.puts 'test'
          expect(subject.to_s).to eq("test\n")
        end

        it "appends all given strings to the contained string" do
          subject.puts 'this', 'is', 'a', 'test'
          expect(subject.to_s).to eq("this\nis\na\ntest\n")
        end

        context "when a line break is present at the end of the given string" do
          it "doesn't add any line break" do
            subject.puts "test\n"
            expect(subject.to_s).not_to eq("test\n\n")
          end
        end
      end

      describe "#to_s" do
        context "when the content is empty" do
          it "returns an empty string" do
            expect(subject.to_s).to eq('')
          end
        end

        context "when the content is not empty" do
          it "returns the content's string" do
            subject << 'test'
            expect(subject.to_s).to eq('test')
          end
        end
      end

      describe "#write" do
        it "writes the given string in content" do
          subject.write 'test'
          expect(subject.to_s).to eq('test')
        end

        it "returns the number of bytes written" do
          expect(subject.write('test')).to eq(4)
        end

        context "when the argument is not a string" do
          it "converts it to a string" do
            subject.write 42
            expect(subject.to_s).to eq('42')
          end
        end

        context "when the argument is a non-ascii string" do
          it "returns the correct number of bytes written" do
            expect(subject.write('é')).to eq(1)
          end
        end
      end

      context "when initialized with a string argument" do
        subject { File::Content.new('test') }

        describe "#read" do
          it "reads +length+ bytes from the contained string" do
            expect(subject.read(2)).to eq('te')
          end

          context "when there is nothing else to read" do
            it "returns nil" do
              subject.read 4
              expect(subject.read(1)).to be_nil
            end
          end

          context "when the optional +buffer+ argument is provided" do
            it "inserts the output in the buffer" do
              string = String.new
              subject.read(2, string)
              expect(string).to eq('te')
            end
          end
        end

        describe "#pos" do
          context "when the string has not been read" do
            it "returns 0" do
              expect(subject.pos).to eq(0)
            end
          end

          context "when the string has been read" do
            it "returns the current offset" do
              subject.read 2
              expect(subject.pos).to eq(2)
            end
          end
        end

        describe "#close" do
          it "responds to close" do
            expect(subject).to respond_to(:close)
          end
        end
      end
    end

  end
end
