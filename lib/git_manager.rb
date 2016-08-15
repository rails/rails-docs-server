require 'logging'

# Lightweight wrapper over Git, shells out everything.
class GitManager
  include Logging

  attr_reader :basedir

  def initialize(basedir)
    @basedir = File.expand_path(basedir)
  end

  def remote_rails_url
    'https://github.com/rails/rails.git'
  end

  def update_master
    Dir.chdir(basedir) do
      unless Dir.exists?('master')
        log "cloning master into #{basedir}/master"
        system "git clone -q #{remote_rails_url} master"
      end

      Dir.chdir('master') do
        log 'updating master'

        # Bundler may modify BUNDLED WITH in Gemfile.lock and that may prevent
        # git pull from succeeding. Starting with Bundler 1.10, if Gemfile.lock
        # does not change BUNDLED WITH is left as is, even if versions differ,
        # but since docs generation is automated better play safe.
        system 'git checkout Gemfile.lock'
        system 'git pull -q'
      end
    end
  end

  def checkout(tag)
    Dir.chdir(basedir) do
      log "checking out tag #{tag}"
      system "git clone -q #{remote_rails_url} #{tag}"

      Dir.chdir(tag) do
        system "git checkout -q #{tag}"
      end
    end
  end

  def release_tags
    Dir.chdir("#{basedir}/master") do
      `git tag`.scan(/^v[\d.]+$/)
    end
  end

  def tag_date(tag)
    Dir.chdir("#{basedir}/master") do
      `git for-each-ref --format="%(taggerdate:iso8601)" refs/tags/#{tag}`.chomp
    end
  end

  def short_sha1
    sha1[0, 7]
  end

  def sha1
    Dir.chdir("#{basedir}/master") do
      `git rev-parse HEAD`.chomp
    end
  end
end
