# Changelog

## HEAD

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
