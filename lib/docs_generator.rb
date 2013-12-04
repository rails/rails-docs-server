require 'logging'
require 'docs_compressor'
require 'git_manager'

require 'target/v3_2_x'
require 'target/v4_0_0'
require 'target/current'
require 'target/master'

# This class is responsible for coordinating docs generation.
#
# The documentation is generated below `basedir`. There, each release and master
# have their own directory, and a stable symlink points to the most recent
# stable release:
#
#   tag1
#   tag2
#   tag3
#   ...
#   tagN
#   stable -> tagN
#   master
#
# Then it checks the tags of the project and detects new releases in any of the
# branches. If there are any (from 3.2 up), the corresponding target class is
# responsible for the actual generations. The target class is who knows which
# ruby and bundler versions it needs, which are the directories for API and
# guides, and how are they generated.
#
# If new releases are detected, symlinks are adjusted as needed. Note that the
# API and guides directories get symlinks to all the previous versions.
#
# Once everything related to stable docs is done, edge docs are generated.
#
# Documentation files are further compressed to leverage nginz gzip_static.
#
# The docs generator assumes a master directory with an up to date working
# copy, it is the responsability of the caller to get that in place via the
# git manager. It is also the responsibility of the caller to ensure there is
# only one generator being executed at the same time.
class DocsGenerator
  include Logging

  attr_reader :basedir, :git_manager

  def initialize(basedir, git_manager=GitManager.new(basedir))
    @basedir     = File.expand_path(basedir)
    @git_manager = git_manager
  end

  def generate
    generate_stable_docs
    generate_edge_docs
  end

  def generate_stable_docs
    new_stable_docs = false

    git_manager.release_tags.each do |tag|
      if generate_stable_docs_for?(tag)
        generate_stable_docs_for(tag)
        new_stable_docs = true
      end
    end

    adjust_symlinks if new_stable_docs
  end

  def generate_stable_docs_for?(tag)
    major, minor = version(tag)
    (major > 3 || (major == 3 && minor == 2)) && !Dir.exists?("#{basedir}/#{tag}")
  end

  def generate_stable_docs_for(tag)
    git_manager.checkout(tag)

    generator = stable_generator_for(tag)
    generator.generate

    DocsCompressor.new(generator.api_output).compress
    DocsCompressor.new(generator.guides_output).compress
  end

  def generate_edge_docs
    generator = Target::Master.new(git_manager.short_sha1, "#{basedir}/master")
    generator.generate

    DocsCompressor.new(generator.api_output).compress
    DocsCompressor.new(generator.guides_output).compress
  end

  def stable_generator_for(tag)
    if tag.start_with?('v3.2.')
      Target::V3_2_x
    elsif tag == 'v4.0.0'
      Target::V4_0_0
    else
      Target::Current
    end.new(tag, "#{basedir}/#{tag}")
  end

  def adjust_symlinks
    log 'adjusting symlinks'
    adjust_docs_symlinks
    adjust_stable_symlink
  end

  def adjust_stable_symlink
    FileUtils.rm_f('stable')
    File.symlink(stable_tag, 'stable')
  end

  def adjust_docs_symlinks
    st = stable_tag
    generator = stable_generator_for(st)

    foreach_tag do |tag|
      next if tag == st

      api_symlink = "#{generator.api_output}/#{tag}"
      unless File.symlink?(api_symlink)
        File.symlink(File.expand_path("#{tag}/doc/rdoc"), api_symlink)
      end

      # Some versions do not have guides, others do but directories may be
      # different. Instead of configuring everything just probe the directories.
      %w(railties/guides/output guides/output).each do |dir|
        file_exists = File.exists?("#{tag}/#{dir}")
        log "Checking if #{tag}/#{dir} exists: #{file_exists}"
        if file_exists
          guides_symlink = "#{generator.guides_output}/#{tag}"

          unless File.symlink?(guides_symlink)
            target = "#{generator.guides_output}/#{tag}"
            source = File.expand_path("#{tag}/#{dir}")

            log "Symlinking #{source} to #{target}"

            File.symlink(source, target)
          end
        end
      end
    end
  end

  def stable_tag
    stable_tag = 'v0.0.0'

    foreach_tag do |tag|
      stable_tag = tag if compare_tags(stable_tag, tag) == -1
    end

    stable_tag
  end

  def compare_tags(tag1, tag2)
    version1 = version(tag1)
    version1[3] ||= 0 # tiny

    version2 = version(tag2)
    version2[3] ||= 0 # tiny

    version1 <=> version2
  end

  def version(tag)
    tag.scan(/\d+/).map(&:to_i)
  end

  def foreach_tag
    Dir.foreach(basedir) do |fname|
      yield fname if File.basename(fname) =~ /\Av[\d.]+\z/
    end
  end
end
