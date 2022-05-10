require 'find'
require 'fileutils'
require 'generators/base'
require 'generators/config/main'

module Generators
  class Main < Base
    include Config::Main

    def generate_api
      start = Time.now
      rake 'rdoc', 'EDGE' => '1', 'ALL' => '1'
      delete_orphan_files_in_api(start)
    end

    def generate_guides
      Dir.chdir('guides') do
        rake 'guides:generate:html', 'ALL' => '1'
      end
    end

    private

    def before_generation
      run "gem install bundler"
    end

    # Edge API generation does not remove doc/rdoc to easily have no downtime
    # without playing tricks with the directories. Just overwrite everything
    # optimistically.
    #
    # The downside is that if a file gets deleted, its HTML remains orphan. This
    # method prevents that.
    def delete_orphan_files_in_api(start)
      Find.find(api_output) do |path|
        if path.end_with?('.html') || path.end_with?('.html.gz')
          FileUtils.rm_f(path) if File.mtime(path) < start
        end
      end
    end
  end
end
