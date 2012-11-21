require 'spec_helper'

module FsFaker
  module Fake
    describe Entry do
      it "has a name attribute accessor" do
        f = File.new
        f.name = 'test'
        f.name.should == 'test'
      end

      it "has a mode attribute accessor" do
        f = File.new
        f.mode = 777
        f.mode.should be(777)
      end

      it "has a path attribute accessor" do
        f = File.new
        f.path = '/test'
        f.path.should == '/test'
      end

      describe '.initialize' do
        it "extract its name from the path passed as argument" do
          File.new('/test').name.should == 'test'
        end

        it "sets an empty string as name if none is given" do
          File.new.name.should == ''
        end

        it "set its path as the path passed as argument" do
          File.new('/test').path.should == '/test'
        end
      end
    end
  end
end
