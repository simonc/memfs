require "delegate"

module MemFs
  module Fake
    class File < Entry

      class Content < SimpleDelegator
        attr_accessor :pos

        def initialize(obj = '')
          @string = obj.to_s.dup
          @pos = 0

          __setobj__ @string
        end

        def to_s
          @string
        end

        def puts(*strings)
          strings.each do |str|
            @string << str
            @string << $/ unless str.end_with?($/)
          end
        end

        def read(length = nil, buffer = '')
          length ||= @string.length - @pos
          buffer.replace @string[@pos, length]
          @pos += buffer.bytesize
          buffer.empty? ? nil : buffer
        end

        def close
        end

        def write(string)
          text = string.to_s
          @string << text
          text.size
        end
      end

    end
  end
end
