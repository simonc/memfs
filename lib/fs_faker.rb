require 'fs_faker/version'
require 'fs_faker/dir'
require 'fs_faker/file'

# Provides a clean way to interact with a fake file system.
#
# @example Calling activate with a block.
#   FsFaker.activate do
#     Dir.mkdir '/hello_world'
#     # /hello_world exists here, in memory
#   end
#   # /hello_world doesn't exist and has never been on the real FS
#
# @example Calling activate! and deactivate!.
#   FsFaker.activate!
#     # The fake file system is running here
#   FsFaker.deactivate!
#   # Everything back to normal
module FsFaker
  extend self

  # Keeps track of the original Ruby Dir class.
  OriginalDir  = ::Dir

  # Keeps track of the original Ruby File class.
  OriginalFile = ::File

  # Calls the given block with FsFaker activated.
  #
  # The advantage of using {#activate} against {#activate!} is that, in case an
  # exception occurs, FsFaker is deactivated.
  #
  # @yield with no argument.
  #
  # @example
  #   FsFaker.activate do
  #     Dir.mkdir '/hello_world'
  #     # /hello_world exists here, in memory
  #   end
  #   # /hello_world doesn't exist and has never been on the real FS
  #
  # @example Exception in activate block.
  #   FsFaker.activate do
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

  # Activates the fake file system.
  #
  # @note Don't forget to call {#deactivate!} to disable the fake file system,
  #   you may have some issues in your scripts or tests otherwise.
  #
  # @example
  #   FsFaker.activate!
  #   Dir.mkdir '/hello_world'
  #   # /hello_world exists here, in memory
  #   FsFaker.deactivate!
  #   # /hello_world doesn't exist and has never been on the real FS
  #
  # @see #deactivate!
  # @return nothing.
  def activate!
    Object.class_eval do
      remove_const :Dir
      remove_const :File

      const_set :Dir,  FsFaker::Dir
      const_set :File, FsFaker::File
    end
  end

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

      const_set :Dir,  FsFaker::OriginalDir
      const_set :File, FsFaker::OriginalFile
    end
  end
end
