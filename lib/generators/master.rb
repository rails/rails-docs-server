require 'generators/base'
require 'generators/config/master'

module Generators
  class Master < Base
    include Config::Master

    def generate_api
      rake 'rdoc', 'EDGE' => '1', 'ALL' => '1'
      insert_edge_badge
    end

    def generate_guides
      Dir.chdir('guides') do
        rake 'guides:generate:html', 'ALL' => '1'
        rake 'guides:generate:kindle'
      end
    end

    private

    def insert_edge_badge
      %w(classes files).each do |subdir|
        Find.find("#{api_output}/#{subdir}") do |fname|
          next unless fname.end_with?('.html')

          # This is a bit hackish but simple enough. Future API tools would
          # ideally have support for this like we have in the guides.
          html = File.read(fname)
          unless html.include?('<img src="/edge_badge.png"')
            html.sub!(%r{<body[^>]*>}, '\\&<div><img src="/edge_badge.png" alt="edge badge" style="position:fixed;right:0px;top:0px;z-index:100;border:none;"/></div>')
            File.write(fname, html)
          end
        end
      end

      FileUtils.cp('guides/assets/images/edge_badge.png', api_output)
    end
  end
end
