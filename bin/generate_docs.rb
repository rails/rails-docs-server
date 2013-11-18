$:.unshift(File.expand_path('../../lib', __FILE__))

require 'lock_file'
require 'docs_generator'

LockFile.acquire('docs_generation.lock') do
  generator = DocsGenerator.new(Dir.home)
  generator.generate
end
