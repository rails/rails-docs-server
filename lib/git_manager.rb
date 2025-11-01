require 'fileutils'
require 'logging'
require 'running'
require 'shellwords'

# Lightweight wrapper over Git, shells out everything.
class GitManager
  include Logging
  include Running

  attr_reader :basedir

  def initialize(basedir)
    @basedir = File.expand_path(basedir)
  end

  def remote_rails_url
    "#{github_rails_url}.git"
  end

  def update_main
    Dir.chdir(basedir) do
      unless Dir.exist?('main')
        log "cloning main into #{basedir}/main"
        log_and_system "git clone -q #{remote_rails_url} main"
      end

      Dir.chdir('main') do
        log 'updating main'

        # Bundler may modify BUNDLED WITH in Gemfile.lock and that may prevent
        # git pull from succeeding. Starting with Bundler 1.10, if Gemfile.lock
        # does not change BUNDLED WITH is left as is, even if versions differ,
        # but since docs generation is automated better play safe.
        log_and_system 'git checkout Gemfile.lock'
        log_and_system 'git pull -q'
      end
    end
  end

  def checkout(tag)
    Dir.chdir(basedir) do
      log "fetching archive for tag #{tag}"
      FileUtils.rm_rf(tag)
      FileUtils.mkdir(tag)

      archive_url = remote_archive_url(tag)
      log "downloading #{archive_url}"

      Dir.chdir(tag) do
        command = "curl -sSL #{Shellwords.shellescape(archive_url)} | tar -xzf - --strip-components=1"
        log_and_system 'sh', '-c', command
      end
    end
  end

  def release_tags
    Dir.chdir("#{basedir}/main") do
      `git tag`.scan(/^v[\d.]+$/)
    end
  end

  def short_sha1
    sha1[0, 7]
  end

  def sha1
    Dir.chdir("#{basedir}/main") do
      `git rev-parse HEAD`.chomp
    end
  end

  private

  def remote_archive_url(tag)
    "#{github_rails_url}/archive/refs/tags/#{tag}.tar.gz"
  end

  def github_rails_url
    'https://github.com/rails/rails'
  end
end
