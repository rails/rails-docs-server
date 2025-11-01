require 'logging'
require 'running'

# Lightweight wrapper over Git, shells out everything.
class GitManager
  include Logging
  include Running

  attr_reader :basedir

  def initialize(basedir)
    @basedir = File.expand_path(basedir)
  end

  def remote_rails_url
    'https://github.com/rails/rails.git'
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
      log "checking out tag #{tag}"
      log_and_system "git -c advice.detachedHead=false clone -q --depth 1 --single-branch --branch #{tag} #{remote_rails_url} #{tag}"
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
end
