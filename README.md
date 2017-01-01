![MemFs Logo](https://raw.github.com/simonc/memfs/master/memfs.png)

[![Gem Version](https://badge.fury.io/rb/memfs.svg)](https://badge.fury.io/rb/memfs)
[![Build Status](https://api.travis-ci.org/simonc/memfs.svg?branch=master)](http://travis-ci.org/simonc/memfs)
[![Code Climate](https://codeclimate.com/github/simonc/memfs/badges/gpa.svg)](https://codeclimate.com/github/simonc/memfs)
[![Coverage Status](https://coveralls.io/repos/github/simonc/memfs/badge.svg?branch=master)](https://coveralls.io/github/simonc/memfs?branch=master)

MemFs is an in-memory filesystem that can be used for your tests.

When you're writing code that manipulates files, directories, symlinks, you need
to be able to test it without touching your hard drive. MemFs is made for it.

MemFs is intended for tests but you can use it for any other scenario needing in
memory file system.

MemFs is greatly inspired by the awesome
[FakeFs](https://github.com/defunkt/fakefs).

The main goal of MemFs is to be 100% compatible with the Ruby libraries like
FileUtils.

For French people, the answer is yes, the joke in the name is intended ;)

## Take a look

Here is a simple example of MemFs usage:

``` ruby
MemFs.activate!
File.open('/test-file', 'w') { |f| f.puts "hello world" }
File.read('/test-file') #=> "hello world\n"
MemFs.deactivate!

File.exists?('/test-file') #=> false

# Or with the block syntax

MemFs.activate do
  FileUtils.touch('/test-file', verbose: true, noop: true)
  File.exists?('/test-file') #=> true
end

File.exists?('/test-file') #=> false
```

## Why you may prefer MemFs over FakeFS?

While FakeFS is pretty cool it overrides classes like `FileUtils`. This kind of override is problematic when you rely on real behavior from this kind of tool.

For instance, trying to test the following with FakeFS will not work, the `noop` option will be ignored:

``` ruby
FileUtils.touch('somefile.txt', noop: true)
```

MemFs tries to be **compliant with the Ruby API** by overriding only the low level classes (C classes) like File, Dir or File::Stat leaving the stdlib classes untouched and still working, being less intrusive that way.

Some stdlib classes may be overriden at some point if they don't use `File` or `Dir`, like `Pathname`, etc.

Another key point is that MemFs **aims to implement every single method provided by Ruby classes** (when possible) and to behave and return **exactly** the same way as the original classes.

## Installation

Add this line to your application's Gemfile:

    gem 'memfs'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install memfs

## Usage in tests

### Global activation

Add the following to your `spec_helper.rb`:

``` ruby
RSpec.configure do |config|
  config.before do
    MemFs.activate!
  end

  config.after do
    MemFs.deactivate!
  end
end
```

All the spec will be sandboxed in MemFs.

If you want to set it globally with flag activation, you can do the following in
you `spec_helper.rb` file:

``` ruby
Rspec.configure do |c|
  c.around(:each, memfs: true) do |example|
    MemFs.activate { example.run }
  end
end
```

And then write your specs like this:

``` ruby
it "creates a file", memfs: true do
  subject.create_file('test.rb')
  expect(File.exists?('test.rb')).to be true
end
```

### Local activation

You can choose to activate MemFs only for a specific test:

``` ruby
describe FileCreator do
  describe '.create_file' do
    it "creates a file" do
      MemFs.activate do
        subject.create_file('test.rb')
        expect(File.exists?('test.rb')).to be true
      end
    end
  end
end
```

No real file will be created during the test.

You can also use it for a specific `describe` block:

``` ruby
describe FileCreator do
  before { MemFs.activate! }
  after { MemFs.deactivate! }

  describe '.create_file' do
    it "creates a file" do
      subject.create_file('test.rb')
      expect(File.exists?('test.rb')).to be true
    end
  end
end
```

### Utilities

You can use `MemFs.touch` to quickly create a file and its parent directories:

``` ruby
MemFs.activate do
  MemFs.touch('/path/to/some/file.rb')
  File.exist?('/path/to/some/file.rb') # => true
end
```

## Requirements

* Ruby 2.0 or newer

## Known issues

* MemFs doesn't implement IO so methods like `FileUtils.copy_stream` and `IO.write` are still the originals.
* Similarly, MemFs doesn't implement Kernel, so don't use a naked `open()` call. This uses the `Kernel` class via `method_missing`, which MemFs will not intercept.
* Pipes and Sockets are not handled for now.
* ~`require "pp"` will raise a _superclass mismatch_ exception since MemFs::File does not inherit from IO. The best thing to do is to require pp _before_ MemFs.~

## TODO

* Implement missing methods from `File`, `Dir` and `Stat`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
