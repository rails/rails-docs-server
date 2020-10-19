require 'find'
require 'fileutils'
require 'generators/base'
require 'generators/config/master'

module Generators
  class Master < Base
    include Config::Master

    def generate_api
      start = Time.now
      rake 'rdoc', 'EDGE' => '1', 'ALL' => '1'
      insert_edge_badge
      delete_orphan_files_in_api(start)
    end

    def generate_guides
      Dir.chdir('guides') do
        rake 'guides:generate:html', 'ALL' => '1'
      end
    end

    private

    def insert_edge_badge
      Dir.glob("#{api_output}/**/*.html") do |fname|
        # This is a bit hackish but simple enough. Future API tools would
        # ideally have support for this like we have in the guides.
        html = File.read(fname, encoding: 'ASCII-8BIT')
        unless html.include?('<img src="/edge_badge.png"')
          html.sub!(%r{<body[^>]*>}, '\\&<div><img src="/edge_badge.png" alt="edge badge" style="position:fixed;right:0px;top:0px;z-index:100;border:none;"/></div>')
          File.write(fname, html)
        end
      end

      FileUtils.cp('guides/assets/images/edge_badge.png', api_output)
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
