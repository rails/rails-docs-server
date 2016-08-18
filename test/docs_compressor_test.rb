require_relative 'test_helper'

require 'docs_compressor'

class DocsCompressorTest < Minitest::Test
  def test_compresses_files_of_known_extensions
    in_tmpdir do
      DocsCompressor::EXTENSIONS.each do |ext|
        touch "foo#{ext}"
      end
      touch 'foo.jpg'

      DocsCompressor.new('.').compress

      DocsCompressor::EXTENSIONS.each do |ext|
        assert_exists "foo#{ext}.gz"
      end
      refute_exists 'foo.jpg.gz'
    end
  end

  def test_compresses_files_in_subdirectories
    in_tmpdir do
      mkdir_p 'foo/bar'

      touch 'zoo.html'
      touch 'foo/zoo.html'
      touch 'foo/bar/zoo.html'

      DocsCompressor.new('.').compress

      assert_exists 'zoo.html.gz'
      assert_exists 'foo/zoo.html.gz'
      assert_exists 'foo/bar/zoo.html.gz'
    end
  end

  def test_skips_kindle_directories
    in_tmpdir do
      mkdir_p 'foo/kindle'

      touch 'foo.html'
      touch 'foo/kindle/foo.html'
      touch 'foo/foo.html'

      DocsCompressor.new('.').compress

      assert_exists 'foo.html.gz'
      assert_exists 'foo/foo.html.gz'
      refute_exists 'foo/kindle/foo.html.gz'
    end
  end
end
