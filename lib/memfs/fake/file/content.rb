require 'delegate'

module MemFs
  module Fake
    class File < Entry

      class Content < SimpleDelegator
        attr_accessor :pos

        def close
        end

        def initialize(obj = '')
          @string = obj.to_s.dup
          @pos = 0

          __setobj__ @string
        end

        def puts(*strings)
          strings.each do |str|
            @string << str
            next if str.end_with?($/)
            @string << $/
          end
        end

        def read(length = nil, buffer = '')
          length ||= @string.length - @pos
          buffer.replace @string[@pos, length]
          @pos += buffer.bytesize
          buffer.empty? ? nil : buffer
        end

        def truncate(length)
          @string.replace @string[0, length]
        end

        def to_s
          @string
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
