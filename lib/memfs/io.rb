require 'forwardable'
require 'memfs/filesystem_access'

module MemFs
  class IO
    extend SingleForwardable
    include OriginalFile::Constants

    (OriginalIO.constants - OriginalFile::Constants.constants)
      .each do |const_name|
        const_set(const_name, OriginalIO.const_get(const_name))
      end

    def_delegators :original_io_class,
      :copy_stream

    def self.read(path, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options = {
        mode: File::RDONLY,
        encoding: nil,
        open_args: nil
      }.merge(options)
      open_args = options[:open_args] ||
                  [options[:mode], encoding: options[:encoding]]

      length, offset = args

      file = open(path, *open_args)
      file.seek(offset || 0)
      file.read(length)
    ensure
      file.close if file
    end

    def self.write(path, string, offset = 0, open_args = nil)
      open_args ||= [File::WRONLY, encoding: nil]

      offset = 0 if offset.nil?
      unless offset.respond_to?(:to_int)
        fail TypeError, "no implicit conversion from #{offset.class}"
      end
      offset = offset.to_int

      if offset > 0
        fail NotImplementedError,
          'MemFs::IO.write with offset not yet supported.'
      end

      file = open(path, *open_args)
      file.seek(offset)
      file.write(string)
    ensure
      file.close if file
    end

    def self.original_io_class
      MemFs::OriginalIO
    end
    private_class_method :original_io_class

    attr_writer :autoclose,
      :close_on_exec

    def <<(object)
      fail IOError, 'not opened for writing' unless writable?

      content << object.to_s
    end

    def advise(advice_type, _offset = 0, _len = 0)
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
      defined?(@autoclose) ? !!@autoclose : true
    end

    def binmode
      @binmode = true
      @external_encoding = Encoding::ASCII_8BIT
      self
    end

    def binmode?
      defined?(@binmode) ? @binmode : false
    end

    def close
      self.closed = true
    end

    def closed?
      closed
    end

    def close_on_exec?
      defined?(@close_on_exec) ? !!@close_on_exec : true
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

    def each(sep = $/)
      return to_enum(__callee__) unless block_given?
      fail IOError, 'not opened for reading' unless readable?
      content.each_line(sep) { |line| yield(line) }
      self
    end

    def each_byte
      return to_enum(__callee__) unless block_given?
      fail IOError, 'not opened for reading' unless readable?
      content.each_byte { |byte| yield(byte) }
      self
    end
    alias_method :bytes, :each_byte

    def each_char
      return to_enum(__callee__) unless block_given?
      fail IOError, 'not opened for reading' unless readable?
      content.each_char { |char| yield(char) }
      self
    end
    alias_method :chars, :each_char

    def fileno
      entry.fileno
    end

    def pos
      entry.pos
    end

    def print(*objs)
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
