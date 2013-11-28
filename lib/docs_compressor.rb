require 'find'
require 'fileutils'
require 'shellwords'
require 'logging'

# Compresses HTML, JavaScript, and CSS under the given directory, recursively.
#
# We do this to leverage gzip_static in nginx.
class DocsCompressor
  include Logging

  EXTENSIONS = %w(.js .html .css)

  def initialize(dir)
    @dir = dir
  end

  def compress
    log "compressing #@dir"

    Find.find(@dir) do |file|
      # The directory with content for the Kindle version of the guides has
      # HTML files used to build the .mobi file, but they are not served, so
      # there is no need to compress them.
      if File.basename(file) == 'kindle'
        Find.prune
      elsif compress_file?(file)
        compress_file(file)
      end
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
    EXTENSIONS.include?(File.extname(file)) && !FileUtils.uptodate?(gzname(file), [file])
  end
end
