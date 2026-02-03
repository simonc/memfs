# Changelog

## 2.0.0 (2026-02-03)

* ADD: Support for Ruby 3.x and 4.x
* ADD: `Dir.empty?`
* ADD: `IO#fileno` and `Dir#fileno` raise `NotImplementedError`
* ADD: `File.birthtime` and `File#birthtime`
* ADD: `File.empty?`
* ADD: `File::Stat#nlink` (#39 by @djberg96)
* ADD: `Dir.mktmpdir` (#52 by @djberg96)
* ADD: Support for `Tempfile.create`
* FIX: Fixing the inverted _read_ and _execute_ bitmasks (#41 by @micahlee)
* ADD: Dependabot configuration
* CHG: Replacing Travis CI with GitHub Actions
* ADD: Adding Windows support

### Breaking

* **DEL: Dropping support for Ruby < 3.2**
* CHG: Renaming the `master` branch to `main`

## 1.0.0 (2017-01-01)

:warning: This version drops support for Ruby 1.9.

* ADD: Support for Ruby 2.4.0
* ADD: Support for _Pathname_ in `Dir.glob` (PR #21 by @craigw)
* ADD: `MemFs.halt` to switch back to the real file-system (PR #24 by @thsur)
* ADD: Basic support for `IO.write` (PR #20 by @rmm5t)
* FIX: Reset the file position when reopened (PR #23 by @jimpo)
* FIX: Ignore trailing slashes when searching an entry (issue #26)
* FIX: Making `File` inherit from `IO` to fix 3rd-party related issues
* FIX: Ensure `File.new` on a symlink raises if target is absent

## 0.5.0 (2015-09-13)

* ADD: Support for _mode_ to `Dir.mkdir`, `FileUtils.mkdir` and `FileUtils.mkdir_p` (@raeno)
* ADD: Support for Ruby 2.2 (@raeno)

## 0.4.3 (2015-02-14)

* ADD: `File::SEPARATOR` and `File::ALT_SEPARATOR`
* FIX: Support `YAML.load_file` by handling `r:bom|utf-8` open mode

## 0.4.2 (2015-02-14)

* ADD: `File#external_encoding`
* FIX: Undefined local variable or method `fs' for MemFs::File

## 0.4.1 (2014-07-24)

* FIX: Support for 1.9.3 broken by File::FNM_EXTGLOB

## 0.4.0 (2014-07-18)

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

## 0.3.0 (2014-03-08)

* FIX: The gem is now Ruby 1.9 compatible

## 0.2.0 (2014-03-07)

* ADD: Allowing magic creation of files with `MemFs.touch`
* ADD: `Dir#each`
* ADD: `Dir.delete`
* ADD: `Dir.exist?`
* ADD: `Dir.foreach`
* ADD: `Dir.home`
* ADD: `Dir.new`
* ADD: `Dir.unlink`
* FIX: File.new now truncates a file when opening mode says so

## 0.1.0 (2013-08-25)

* ADD: Adding `File` missing methods - #3

## 0.0.2 (2013-07-12)

* ADD: Adding the MIT license to the gemspec file - #2
