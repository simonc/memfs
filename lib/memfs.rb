# frozen_string_literal: true

require 'memfs/version'
require 'fileutils'

# Provides a clean way to interact with a fake file system.
#
# @example Calling activate with a block.
#   MemFs.activate do
#     Dir.mkdir '/hello_world'
#     # /hello_world exists here, in memory
#   end
#   # /hello_world doesn't exist and has never been on the real FS
#
# @example Calling activate! and deactivate!.
#   MemFs.activate!
#     # The fake file system is running here
#   MemFs.deactivate!
#   # Everything back to normal
module MemFs
  # Keeps track of the original Ruby Dir class.
  OriginalDir  = ::Dir

  # Keeps track of the original Ruby File class.
  OriginalFile = ::File

  # Keeps track of the original Ruby IO class.
  OriginalIO = ::IO

  def self.ruby_version_gte?(version) # :nodoc:
    Gem::Version.new(RUBY_VERSION) >= Gem::Version.new(version)
  end

  def self.windows?
    /mswin|bccwin|mingw/ =~ RUBY_PLATFORM
  end

  # Returns the platform-specific root path (e.g., '/' on Unix, 'D:/' on Windows)
  def self.platform_root
    @platform_root || default_platform_root
  end

  # Allows setting a custom platform root (mainly for testing)
  def self.platform_root=(value)
    @platform_root = value
  end

  # Resets platform_root to the default value
  def self.reset_platform_root!
    @platform_root = nil
  end

  # Returns the default platform root based on the current OS
  def self.default_platform_root
    if windows?
      # Normalize drive letter to uppercase
      OriginalFile.expand_path('/').sub(/\A([a-z]):/) { "#{::Regexp.last_match(1).upcase}:" }
    else
      '/'
    end
  end

  # Check if a path is the root path (handles both '/' and 'D:/')
  def self.root_path?(path)
    return false if path.nil?

    normalized = normalize_path(path)
    normalized == platform_root || normalized == '/'
  end

  # Normalize path for consistent handling
  # rubocop:disable Metrics/MethodLength
  def self.normalize_path(path)
    return path unless path.is_a?(String)

    # Reject UNC paths
    fail ArgumentError, "UNC paths are not supported: #{path}" if path.start_with?('\\\\', '//')

    # Convert backslashes to forward slashes
    path = path.tr('\\', '/')

    return path unless windows?

    # Normalize drive letter to uppercase
    path = path.sub(/\A([a-z]):/) { "#{::Regexp.last_match(1).upcase}:" }

    # Handle drive-relative paths like 'D:foo' or 'D:.' (no slash after colon)
    # and bare drive letters like 'D:' (current directory on drive D)
    # Convert to absolute paths since our fake fs doesn't support per-drive working directories
    if path.match?(/\A[A-Z]:\z/) # Bare drive like 'D:'
      path = "#{path}/"
    elsif path.match?(/\A[A-Z]:[^\/]/) # Drive-relative like 'D:foo' or 'D:.'
      path = path.sub(/\A([A-Z]):/, '\1:/')
    end

    # Convert bare '/' to platform root on Windows
    if path == '/'
      platform_root
    elsif path.start_with?('/') && !path.match?(%r{\A[A-Z]:/})
      # Convert '/foo' to 'D:/foo' on Windows
      "#{platform_root}#{path[1..]}"
    else
      path
    end
  end
  # rubocop:enable Metrics/MethodLength

  require 'memfs/file_system'
  require 'memfs/dir'
  require 'memfs/file'
  require 'memfs/file/stat'

  # Calls the given block with MemFs activated.
  #
  # The advantage of using {#activate} against {#activate!} is that, in case an
  # exception occurs, MemFs is deactivated.
  #
  # @yield with no argument.
  #
  # @example
  #   MemFs.activate do
  #     Dir.mkdir '/hello_world'
  #     # /hello_world exists here, in memory
  #   end
  #   # /hello_world doesn't exist and has never been on the real FS
  #
  # @example Exception in activate block.
  #   MemFs.activate do
  #     raise "Some Error"
  #   end
  #   # Still back to the original Ruby classes
  #
  # @return nothing.
  def activate
    activate!
    yield
  ensure
    deactivate!
  end
  module_function :activate

  # Activates the fake file system.
  #
  # @note Don't forget to call {#deactivate!} to disable the fake file system,
  #   you may have some issues in your scripts or tests otherwise.
  #
  # @example
  #   MemFs.activate!
  #   Dir.mkdir '/hello_world'
  #   # /hello_world exists here, in memory
  #   MemFs.deactivate!
  #   # /hello_world doesn't exist and has never been on the real FS
  #
  # @see #deactivate!
  # @return nothing.
  def activate!(clear: true)
    Object.class_eval do
      remove_const :Dir
      remove_const :File
      remove_const :IO

      const_set :Dir, MemFs::Dir
      const_set :IO, MemFs::IO
      const_set :File, MemFs::File
    end

    MemFs::FileSystem.instance.clear! if clear
  end
  module_function :activate!

  # Deactivates the fake file system.
  #
  # @note This method should always be called when using activate!
  #
  # @see #activate!
  # @return nothing.
  def deactivate!
    Object.class_eval do
      remove_const :Dir
      remove_const :File
      remove_const :IO

      const_set :Dir, MemFs::OriginalDir
      const_set :IO, MemFs::OriginalIO
      const_set :File, MemFs::OriginalFile
    end
  end
  module_function :deactivate!

  # Switches back to the original file system, calls the given block (if any),
  # and switches back afterwards.
  #
  # If a block is given, all file & dir operations (like reading dir contents or
  # requiring files) will operate on the original fs.
  #
  # @example
  #   MemFs.halt do
  #     puts Dir.getwd
  #   end
  # @return nothing
  def halt
    deactivate!

    yield if block_given?
  ensure
    activate!(clear: false)
  end
  module_function :halt

  # Creates a file and all its parent directories.
  #
  # @param path: The path of the file to create.
  #
  # @return nothing.
  def touch(*paths)
    fail 'Always call MemFs.touch inside a MemFs active context.' if ::File != MemFs::File

    paths.each do |path|
      FileUtils.mkdir_p File.dirname(path)
      FileUtils.touch path
    end
  end
  module_function :touch
end
