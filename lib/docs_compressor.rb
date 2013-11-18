require 'find'
require 'shellwords'

class DocsCompressor
  EXTENSIONS = %w(.js .html .css)

  def initialize(dir)
    @dir = dir
  end

  def compress
    Find.find(@dir) do |file|
      compress_file(file) if compress_file?(file)
    end
  end

  private

  def gzname(file)
    "#{file}.gz"
  end

  def compress_file(file)
    orig = Shellwords.shellescape(file)
    dest = Shellwords.shellescape(gzname(file))

    system %(gzip -c -9 #{orig} > #{dest})
  end

  def compress_file?(file)
    if EXTENSIONS.include?(File.extname(file))
      !File.exists?(gzname(file)) || File.mtime(gzname(file)) < File.mtime(file)
    end
  end
end
