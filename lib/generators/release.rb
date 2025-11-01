require 'fileutils'
require 'version_number'
require 'generators/base'
require 'generators/config/release'

module Generators
  class Release < Base
    include Config::Release

    def initialize(tag, basedir)
      super(tag, basedir)
      @version_number = VersionNumber.new(tag)
    end

    def before_generation
      if version_number == '4.2.10'
        log "rm Gemfile.lock"
        # There is a dependency on json that doesn't play well with the following downgrade.
        FileUtils.rm_f('Gemfile.lock')

        patch 'Gemfile' do |contents|
          # See the comment above for 4.2.9.
          contents.sub(/gem 'sdoc'.*/, "gem 'sdoc', '~> 0.4.0'")
        end
      elsif version_number == '8.0.3'
        # sdoc 2.6.2 has a bug with RDoc
        patch 'Gemfile' do |contents|
          contents.sub(/gem "sdoc".*/, "gem \"sdoc\", \"~> 2.6.4\"")
        end

        patch 'guides/assets/stylesrc/components/_code-container.scss' do |contents|
          contents.sub(/^\s+overflow: scroll;/, "")
        end
      elsif version_number >= '5.1.2' && version_number <= '5.1.4'
        patch 'guides/source/documents.yaml' do |contents|
          # This guide was deleted and prevented Kindle guides from being
          # generated. See https://github.com/rails/rails/issues/29865.
          contents.sub(/^\s+name: Profiling Rails Applications[^-]+-\n/, '')
        end
      elsif version_number >= '6.1.7.9' && version_number < '7.0.0'
        patch 'Gemfile' do |contents|
          contents << "\ngem \"zeitwerk\", \"< 2.7.0\"\n"
          contents << "\ngem \"public_suffix\", \"< 6.0\"\n"
          contents << "\ngem \"loofah\", \"< 2.21.0\"\n"
        end
        bundle 'lock --add-platform ruby --update nokogiri --update azure-storage-blob --update public_suffix --update zeitwerk --update sqlite3'
      elsif version_number >= '6.1.7.5' && version_number < '7.0.0'
        patch 'Gemfile' do |contents|
          contents << "\ngem \"loofah\", \"< 2.21.0\"\n"
        end
      elsif version_number >= '7.0.9' && version_number < '7.1.0'
        patch 'Gemfile.lock' do |contents|
          contents.sub(/^BUNDLED WITH\n\s+\d+\.\d+\.\d+/, "BUNDLED WITH\n   2.4.19")
        end
      elsif version_number >= '5.2.6'
        run 'gem install bundler'

        patch 'Gemfile' do |contents|
          contents.sub!(/gem \"delayed_job\".*/, "# gem \"delayed_job\"")
          contents.sub!(/gem \"delayed_job_active_record\".*/, "# gem \"delayed_job_active_record\"")
          contents
        end
      end
    end

    def generate_api
      rake 'rdoc'
    end

    def generate_guides
      Dir.chdir('guides') do
        rake 'guides:generate:html',   'RAILS_VERSION' => target
        rake 'guides:generate:kindle', 'RAILS_VERSION' => target
      end
    end

    private

    def version_number
      @version_number
    end
  end
end
