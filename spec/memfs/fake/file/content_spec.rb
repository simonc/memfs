require 'spec_helper'

module MemFs
  module Fake

    describe File::Content do
      subject { File::Content.new }

      it "has a string" do
        subject.to_s.should == ''
      end

      describe "#initialize" do
        context "when no argument is given" do
          it "initialize the contained string to an empty one" do
            subject.to_s.should == ''
          end
        end

        context "when an argument is given" do
          context "when the argument is a string" do
            let(:base_string) { 'test' }
            subject { File::Content.new(base_string) }

            it "initialize the contained string with the given one" do
              subject.to_s.should == 'test'
            end

            it "duplicates the original string to prevent modifications on it" do
              subject.to_s.should_not be(base_string)
            end
          end

          context "when the argument is not a string" do
            subject { File::Content.new(42) }

            it "initialize the contained string to the result of a call of to_s on the argument" do
              subject.to_s.should == '42'
            end
          end
        end
      end

      describe "#puts" do
        it "appends the given string to the contained string" do
          subject.puts "test"
          subject.to_s.should == "test\n"
        end

        it "appends all given strings to the contained string" do
          subject.puts 'this', 'is', 'a', 'test'
          subject.to_s.should == "this\nis\na\ntest\n"
        end

        it "doesn't add any line break if one is already present at the end of the given string" do
          subject.puts "test\n"
          subject.to_s.should_not == "test\n\n"
        end
      end

      describe "#<<" do
        it "writes the given string to the contained string" do
          subject << 'test'
          subject.to_s.should == 'test'
        end
      end

      context "when initialized with a string argument" do
        subject { File::Content.new('test') }

        describe "#read" do
          it "reads +length+ bytes from the contained string" do
            subject.read(2).should == "te"
          end

          context "when there is nothing else to read" do
            it "returns nil" do
              subject.read(4)
              expect(subject.read(1)).to be_nil
            end
          end

          context "when the optional +buffer+ argument is provided" do
            it "inserts the output in the buffer" do
              s = String.new
              subject.read(2, s)
              s.should == "te"
            end
          end
        end

        describe "#pos" do
          it "returns 0 when the string has not been read" do
            subject.pos.should == 0
          end

          it "returns the current offset" do
            subject.read(2)
            subject.pos.should be(2)
          end
        end

        describe "#close" do
          
        end
      end

      describe "#write" do
        it "writes the given string in content" do
          subject.write('test')
          subject.to_s.should == 'test'
        end

        it "returns the number of bytes written" do
          subject.write('test').should be(4)
        end

        context "when the argument is not a string" do
          it "will be converted to a string using to_s" do
            subject.write 42
            subject.to_s.should == '42'
          end
        end
      end
    end

  end
end
