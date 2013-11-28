require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'

$:.unshift(File.realpath("#{__dir__}/../lib"))

class MiniTest::Test
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
    assert File.exists?(fname)
  end

  def refute_exists(fname)
    refute File.exists?(fname)
  end
end

require 'logging'
module Logging
  def log(*)
  end
end
