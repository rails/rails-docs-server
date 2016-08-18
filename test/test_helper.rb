require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'

$:.unshift(File.realpath("#{__dir__}/../lib"))

Minitest::Test.class_eval do
  include FileUtils

  def in_tmpdir
    Dir.mktmpdir do |tmpdir|
      chdir(tmpdir) do
        yield
      end
    end
  end

  def chdir(dirname)
    Dir.chdir(dirname) do
      yield
    end
  end

  def assert_exists(fname)
    assert File.exist?(fname)
  end

  def refute_exists(fname)
    refute File.exist?(fname)
  end
end

require 'logging'
module Logging
  prepend Module.new {
    def log(*)
    end
  }
end
