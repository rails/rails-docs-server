require 'set'
require 'logging'
require 'docs_compressor'
require 'git_manager'
require 'generators/release'
require 'generators/main'
require 'version_number'

# This class is responsible for coordinating docs generation.
#
# The documentation is generated below `basedir`. There, each release and main
# have their own directory:
#
#   tag1
#   tag2
#   tag3
#   ...
#   tagN
#   main
#
# The generator checks the current release tags of the project to detect new
# releases in any of the branches from 3.2 up.
#
# Top-level symlinks point to the actual root directories. If we assume v4.1.0
# is the current stable release, this is the idea:
#
#   api/v3.2.0 -> basedir/v3.2.0/doc/rdoc
#   api/v3.2   -> api/v3.2.0
#   api/v4.1.0 -> basedir/v4.1.0/doc/rdoc
#   api/v4.1   -> api/v4.1.0
#   api/stable -> api/v4.1.0
#   api/edge   -> basedir/main/doc/rdoc
#
# and same for guides:
#
#   guides/v3.2.0 -> basedir/v3.2.0/railties/guides/output
#   guides/v3.2   -> guides/v3.2.0
#   guides/v4.1.0 -> basedir/v4.1.0/guides/output
#   guides/v4.1   -> guides/v4.1.0
#   guides/stable -> guides/v4.1.0
#   guides/edge   -> basedir/main/guides/output
#
# If new releases are detected, symlinks are adjusted as needed.
#
# Once everything related to release docs is done, edge docs are generated.
#
# Documentation files are further compressed to leverage NGINX gzip_static.
#
# The docs generator assumes a main directory with an up to date working
# copy, it is the responsability of the caller to get that in place via the
# git manager. It is also the responsibility of the caller to ensure there is
# only one generator being executed at the same time.
class DocsGenerator
  include Logging

  API    = 'api'
  GUIDES = 'guides'
  STABLE = 'stable'
  EDGE   = 'edge'

  attr_reader :basedir, :git_manager

  # To instantiate a docs generator you need to pass the base directory under
  # which the structure documented above has to be generated. This is the home
  # directory in the docs server.
  #
  # @param basedir [String]
  # @param git_manager [GitManager]
  def initialize(basedir, git_manager=GitManager.new(basedir))
    @basedir     = File.expand_path(basedir)
    @git_manager = git_manager
  end

  def generate
    Dir.chdir(basedir) do
      generate_release_docs
      generate_edge_docs
    end
  end

  def generate_release_docs
    new_release_docs = false

    git_manager.release_tags.each do |tag|
      if generate_docs_for_release?(tag)
        generate_docs_for_release(tag)
        new_release_docs = true
      end
    end

    adjust_symlinks_for_series if new_release_docs
  end

  def generate_docs_for_release?(tag)
    VersionNumber.new(tag) >= '3.2' && !Dir.exist?(tag)
  end

  def generate_docs_for_release(tag)
    git_manager.checkout(tag)

    generator = Generators::Release.new(tag, tag)
    generator.generate

    DocsCompressor.new(generator.api_output).compress
    DocsCompressor.new(generator.guides_output).compress

    create_api_symlink(generator.api_output, tag)
    create_guides_symlink(generator.guides_output, tag)
  end

  def generate_edge_docs
    generator = Generators::Main.new(git_manager.short_sha1, 'main')
    generator.generate

    DocsCompressor.new(generator.api_output).compress
    DocsCompressor.new(generator.guides_output).compress

    # Force the recreation of the symlink to be forward compatible, if the docs
    # structure changes in main we need the symlink to point to the new dirs.
    create_api_symlink(generator.api_output, EDGE, force: true)
    create_guides_symlink(generator.guides_output, EDGE, force: true)
  end

  def create_api_symlink(origin, symlink, options={})
    create_symlink(API, origin, symlink, options)
  end

  def create_guides_symlink(origin, symlink, options={})
    create_symlink(GUIDES, origin, symlink, options)
  end

  def create_symlink(dir, origin, symlink, options)
    FileUtils.mkdir_p(dir)

    Dir.chdir(dir) do
      FileUtils.rm_f(symlink) if options[:force]
      File.symlink(origin, symlink)
    end
  end

  def adjust_symlinks_for_series
    series.each do |series, target|
      [API, GUIDES].each do |_|
        Dir.chdir(_) do
          unless File.exist?(series) && File.readlink(series) == target
            FileUtils.rm_f(series)
            File.symlink(target, series)
          end
        end
      end
    end
  end

  def series
    rds = release_directories

    {STABLE => max_tag(rds)}.tap do |series|
      directories_per_serie = rds.to_set.classify {|rd| rd[/v\d+.\d+/]}

      directories_per_serie.each do |s, dirs|
        series[s] = max_tag(dirs)
      end
    end
  end

  def release_directories
    [].tap do |dirs|
      Dir.foreach(basedir) do |fname|
        dirs << fname if File.basename(fname) =~ /\Av[\d.]+\z/
      end
    end
  end

  def max_tag(tags)
    tags.max {|t, g| VersionNumber.new(t) <=> VersionNumber.new(g)}
  end
end
