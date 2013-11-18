class GitManager
  attr_reader :basedir

  def initialize(basedir)
    @basedir = File.expand_path(basedir)
  end

  def remote_rails_url
    'https://github.com/rails/rails.git'
  end

  def checkout(tag)
    Dir.chdir(basedir) do
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

  def sha1
    Dir.chdir("#{basedir}/master") do
      `git rev-parse HEAD`.chomp
    end
  end

  def version(tag)
    tag.scan(/\d+/).map(&:to_i)
  end
end
