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
  def activate!
    Object.class_eval do
      remove_const :Dir
      remove_const :File

      const_set :Dir,  MemFs::Dir
      const_set :File, MemFs::File
    end

    MemFs::FileSystem.instance.clear!
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

      const_set :Dir,  MemFs::OriginalDir
      const_set :File, MemFs::OriginalFile
    end
  end
  module_function :deactivate!

  # Creates a file and all its parent directories.
  #
  # @param path: The path of the file to create.
  #
  # @return nothing.
  def touch(*paths)
    if ::File != MemFs::File
      fail 'Always call MemFs.touch inside a MemFs active context.'
    end

    paths.each do |path|
      FileUtils.mkdir_p File.dirname(path)
      FileUtils.touch path
    end
  end
  module_function :touch
end
