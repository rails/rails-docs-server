require_relative 'test_helper'

require 'git_manager'
require 'shellwords'

class GitManagerTest < Minitest::Test
  def create_repository
    system 'git init -q .'
    system 'git config user.name "Test"'
    system 'git config user.email "test@example.com"'
    system 'git config commit.gpgsign false'
    system 'touch README'
    system 'git add README'
    system 'git commit -q -m "test" README'
  end

  def test_checkout
    in_tmpdir do
      mkdir_p 'basedir/main'

      chdir 'basedir/main' do
        create_repository

        system 'echo t1 > README'
        system 'git commit -aqm "test"'
        system 'git tag t1'

        system 'echo t2 > README'
        system 'git commit -aqm "test"'
        system 'git tag t2'

        %w(t1 t2).each do |tag|
          archive_path = File.expand_path("../#{tag}.tar.gz", Dir.pwd)
          system 'sh', '-c', "git archive --format=tar --prefix=rails-#{tag}/ #{tag} | gzip > #{Shellwords.escape(archive_path)}"
        end
      end

      gm = GitManager.new('basedir')
      archive_dir = File.expand_path('basedir')
      gm.stub(:remote_archive_url, ->(requested_tag) { "file://#{File.expand_path("#{requested_tag}.tar.gz", archive_dir)}" }) do
        gm.checkout('t1')
      end

      assert Dir.exist?('basedir/t1')
      assert_equal "t1\n", File.read('basedir/t1/README')
    end
  end

  def test_release_tags
    in_tmpdir do
      mkdir_p 'basedir/main'

      chdir 'basedir/main' do
        create_repository
        %w(0.9.4.1 2.3.9.pre 3.0.0_RC2 3.2.8.rc1 3.2.14 v4.0.0.beta1 4.0.1).each do |version|
          system "git tag v#{version}"
        end
      end

      expected = %w(v0.9.4.1 v3.2.14 v4.0.1)
      assert_equal expected, GitManager.new('basedir').release_tags.sort
    end
  end

  def test_sha1_and_short_sha1
    in_tmpdir do
      mkdir_p 'basedir/main'

      sha1 = nil
      chdir 'basedir/main' do
        create_repository
        sha1 = `git rev-parse HEAD`.chomp
      end

      git_manager = GitManager.new('basedir')

      assert_equal sha1, git_manager.sha1
      assert_equal sha1[0, 7], git_manager.short_sha1
    end
  end
end
