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

  def short_sha1
    sha1[0, 7]
  end

  def sha1
    Dir.chdir("#{basedir}/master") do
      `git rev-parse HEAD`.chomp
    end
  end
end
