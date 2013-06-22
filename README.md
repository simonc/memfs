# MemFs [![Build Status](https://secure.travis-ci.org/simonc/memfs.png?branch=master)](http://travis-ci.org/simonc/memfs) [![Code Climate](https://codeclimate.com/github/simonc/memfs.png)](https://codeclimate.com/github/simonc/memfs) [![Coverage Status](https://coveralls.io/repos/simonc/memfs/badge.png?branch=master)](https://coveralls.io/r/simonc/memfs?branch=master)

MemFs is an in-memory filesystem that can be used for your tests.

When you're writing code that manipulates files, directories, symlinks, you need
to be able to test it without touching your hard drive. MemFs is made for it.

MemFs is greatly inspired by the awesome [FakeFs](https://github.com/defunkt/fakefs).

The main goal of MemFs is to be 100% compatible with the Ruby libraries like FileUtils.

For french guys, the answer is yes, the joke in the name is intended ;)

## Take a look

Here is a simple example of MemFs usage:

``` ruby
MemFs.activate!
File.open('/test-file', 'w') { |f| f.puts "hello world" }
MemFs.deactivate!

# Or with the block syntax

MemFs.activate do
  FileUtils.touch('/test-file', verbose: true, noop: true)
end
```

## Installation

Add this line to your application's Gemfile:

    gem 'memfs'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install memfs

## Requirements

* Ruby 2.0+

## Usage


## Known issues

* MemFs doesn't implement IO so FileUtils.copy_stream is still the original one

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
