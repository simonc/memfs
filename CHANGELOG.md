# Changelog

## HEAD

* ADD: `Dir.empty?` from Ruby 2.4
* ADD: `IO#fileno` and `Dir#fileno` raise `NotImplementedError`
* ADD: `File.birthtime` and `File#birthtime`

## 1.0.0

:warning: This version drops support for Ruby 1.9.

* ADD: Support for Ruby 2.4.0
* ADD: Support for _Pathname_ in `Dir.glob` (PR #21 by @craigw)
* ADD: `MemFs.halt` to switch back to the real file-system (PR #24 by @thsur)
* ADD: Basic support for `IO.write` (PR #20 by @rmm5t)
* FIX: Reset the file position when reopened (PR #23 by @jimpo)
* FIX: Ignore trailing slashes when searching an entry (issue #26)
* FIX: Making `File` inherit from `IO` to fix 3rd-party related issues
* FIX: Ensure `File.new` on a symlink raises if target is absent

## 0.5.0

* ADD: Support for _mode_ to `Dir.mkdir`, `FileUtils.mkdir` and `FileUtils.mkdir_p` (@raeno)
* ADD: Support for Ruby 2.2 (@raeno)

## 0.4.3

* ADD: `File::SEPARATOR` and `File::ALT_SEPARATOR`
* FIX: Support `YAML.load_file` by handling `r:bom|utf-8` open mode

## 0.4.2

* ADD: `File#external_encoding`
* FIX: Undefined local variable or method `fs' for MemFs::File

## 0.4.1

* FIX: Support for 1.9.3 broken by File::FNM_EXTGLOB

## 0.4.0

* ADD: `Dir.chroot`
* ADD: `Dir.glob` and `Dir[]`
* ADD: `Dir.open`
* ADD: `Dir.tmpdir`
* ADD: `Dir#close`
* ADD: `Dir#path`
* ADD: `Dir#pos=`
* ADD: `Dir#pos`
* ADD: `Dir#read`
* ADD: `Dir#rewind`
* ADD: `Dir#seek`
* ADD: `Dir#tell`
* ADD: `Dir#to_path`
* FIX: Internal implementation methods are now private

## 0.3.0

* FIX: The gem is now Ruby 1.9 compatible

## 0.2.0

* ADD: Allowing magic creation of files with `MemFs.touch`
* ADD: `Dir#each`
* ADD: `Dir.delete`
* ADD: `Dir.exist?`
* ADD: `Dir.foreach`
* ADD: `Dir.home`
* ADD: `Dir.new`
* ADD: `Dir.unlink`
* FIX: File.new now truncates a file when opening mode says so

## 0.1.0

* ADD: Adding `File` missing methods - #3

## 0.0.2

* ADD: Adding the MIT license to the gemspec file - #2
