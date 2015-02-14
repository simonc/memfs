require 'forwardable'
require 'memfs/filesystem_access'

module MemFs
  module IO
    module ClassMethods
      def read(path, *args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options = { mode: File::RDONLY, encoding: nil, open_args: nil }.merge(options)
        open_args = options[:open_args] ||
                    [options[:mode], encoding: options[:encoding]]

        length, offset = args

        file = open(path, *open_args)
        file.seek(offset || 0)
        file.read(length)
      ensure
        file.close if file
      end
    end

    module InstanceMethods
      attr_writer :autoclose,
                  :close_on_exec

      def <<(object)
        fail IOError, 'not opened for writing' unless writable?

        content << object.to_s
      end

      def advise(advice_type, offset = 0, len = 0)
        advice_types = [
          :dontneed,
          :noreuse,
          :normal,
          :random,
          :sequential,
          :willneed
        ]
        unless advice_types.include?(advice_type)
          fail NotImplementedError, "Unsupported advice: #{advice_type.inspect}"
        end
        nil
      end

      def autoclose?
        @autoclose.nil? ? true : !!@autoclose
      end

      def binmode
        @binmode = true
        @external_encoding = Encoding::ASCII_8BIT
        self
      end

      def binmode?
        @binmode.nil? ? false : @binmode
      end

      def close
        self.closed = true
      end

      def closed?
        closed
      end

      def close_on_exec?
        @close_on_exec.nil? ? true : !!@close_on_exec
      end

      def eof?
        pos >= content.size
      end
      alias_method :eof, :eof?

      def external_encoding
        if writable?
          @external_encoding
        else
          @external_encoding ||= Encoding.default_external
        end
      end

      def each(sep = $/, &block)
        return to_enum(__callee__) unless block_given?
        fail IOError, 'not opened for reading' unless readable?
        content.each_line(sep) { |line| block.call(line) }
        self
      end

      def each_byte(&block)
        return to_enum(__callee__) unless block_given?
        fail IOError, 'not opened for reading' unless readable?
        content.each_byte { |byte| block.call(byte) }
        self
      end
      alias_method :bytes, :each_byte

      def each_char(&block)
        return to_enum(__callee__) unless block_given?
        fail IOError, 'not opened for reading' unless readable?
        content.each_char { |char| block.call(char) }
        self
      end
      alias_method :chars, :each_char

      def pos
        entry.pos
      end

      def print(*objs)
        $stdout.puts $_.inspect
        objs << $_ if objs.empty?
        self << objs.join($,) << $\.to_s
        nil
      end

      def printf(format_string, *objs)
        print format_string % objs
      end

      def puts(text)
        fail IOError, 'not opened for writing' unless writable?

        content.puts text
      end

      def read(length = nil, buffer = '')
        unless entry
          fail(Errno::ENOENT, path)
        end
        default = length ? nil : ''
        content.read(length, buffer) || default
      end

      def seek(amount, whence = ::IO::SEEK_SET)
        new_pos = case whence
                  when ::IO::SEEK_CUR then entry.pos + amount
                  when ::IO::SEEK_END then content.to_s.length + amount
                  when ::IO::SEEK_SET then amount
                  end

        fail Errno::EINVAL, path if new_pos.nil? || new_pos < 0

        entry.pos = new_pos
        0
      end

      def stat
        File.stat(path)
      end

      def write(string)
        fail IOError, 'not opened for writing' unless writable?

        content.write(string.to_s)
      end

      private

      attr_accessor :closed,
                    :entry,
                    :opening_mode

      attr_reader :path

      def content
        entry.content
      end

      def create_file?
        (opening_mode & File::CREAT).nonzero?
      end

      def readable?
        (opening_mode & File::RDWR).nonzero? ||
        (opening_mode | File::RDONLY).zero?
      end

      def str_to_mode_int(mode)
        return mode unless mode.is_a?(String)

        unless mode =~ /\A([rwa]\+?)([bt])?(:bom)?(\|.+)?\z/
          fail ArgumentError, "invalid access mode #{mode}"
        end

        mode_str = $~[1]
        File::MODE_MAP[mode_str]
      end

      def truncate_file?
        (opening_mode & File::TRUNC).nonzero?
      end

      def writable?
        (opening_mode & File::WRONLY).nonzero? ||
        (opening_mode & File::RDWR).nonzero?
      end
    end
  end
end
