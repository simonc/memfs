$:.unshift 'lib'
require 'memfs'
require 'tmpdir'

MemFs.activate do
  Dir.chdir(Dir.mktmpdir) do
    File.symlink('eloop0', 'eloop1')
    File.symlink('eloop1', 'eloop0')
  end
end
