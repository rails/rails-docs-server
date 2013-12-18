require_relative 'test_helper'

require 'docs_generator'
require 'git_manager'
require 'logging'

class TestDocsGenerator < MiniTest::Test
  def test_version
    docs_generator = DocsGenerator.new('.')

    assert_equal [2, 3, 2, 1], docs_generator.version('v2.3.2.1')
    assert_equal [3, 2, 14], docs_generator.version('v3.2.14')
  end

  def test_stable_tag
    in_tmpdir do
      mkdir 'basedir'

      Dir.chdir('basedir') do
        mkdir 'v4.0.1'
        mkdir 'v4.1.7'
        mkdir 'v4.11.2'
        mkdir 'v3.1.2'
      end

      assert_equal 'v4.11.2', DocsGenerator.new('basedir').stable_tag
    end
  end

  def test_compare_tags
    docs_generator = DocsGenerator.new('.')

    [%w(v2.3.0 v2.3.1), %w(v2.3.2 v2.3.2.1), %w(v3.0.4 v3.1.2), %w(v3.2.8 v4.0.0)].each do |tag1, tag2|
      assert_equal -1, docs_generator.compare_tags(tag1, tag2)
      assert_equal  0, docs_generator.compare_tags(tag1, tag1)
      assert_equal  0, docs_generator.compare_tags(tag2, tag2)
      assert_equal  1, docs_generator.compare_tags(tag2, tag1)
    end
  end

  def test_generates_docs
    skip 'skipping docs generation' unless ENV['TEST_DOCS_GENERATION']

    in_tmpdir do
      mkdir 'basedir'

      git_manager = GitManager.new('basedir')
      git_manager.update_master

      git_manager.stub(:release_tags, %w(v3.2.15 v4.0.0 v4.0.1)) do
        docs_generator = DocsGenerator.new('basedir', git_manager)
        docs_generator.generate
      end

      #
      # --- Stable -------------------------------------------------------------
      #

      Dir.chdir('basedir') do
        tag = 'v3.2.15'
        assert_exists "#{tag}/doc/rdoc/index.html"
        assert_exists "#{tag}/doc/rdoc/index.html.gz"

        assert File.read("#{tag}/doc/rdoc/files/RDOC_MAIN_rdoc.html").include?("Ruby on Rails #{tag}")

        assert_exists "#{tag}/railties/guides/output/index.html"
        assert_exists "#{tag}/railties/guides/output/index.html.gz"
        assert_exists "#{tag}/railties/guides/output/kindle/ruby_on_rails_guides_#{tag}.mobi"

        assert File.read("#{tag}/railties/guides/output/index.html").include?("Ruby on Rails Guides (#{tag})")

        tag = 'v4.0.0'
        assert_exists "#{tag}/doc/rdoc/index.html"
        assert_exists "#{tag}/doc/rdoc/index.html.gz"

        assert File.read("#{tag}/doc/rdoc/files/railties/RDOC_MAIN_rdoc.html").include?("Ruby on Rails #{tag}")

        assert_exists "#{tag}/guides/output/index.html"
        assert_exists "#{tag}/guides/output/index.html.gz"
        assert_exists "#{tag}/guides/output/kindle/ruby_on_rails_guides_#{tag}.mobi"

        assert File.read("#{tag}/guides/output/index.html").include?("Ruby on Rails Guides (#{tag})")

        tag = 'v4.0.1'
        assert_exists "#{tag}/doc/rdoc/index.html"
        assert_exists "#{tag}/doc/rdoc/index.html.gz"

        assert File.read("#{tag}/doc/rdoc/files/railties/RDOC_MAIN_rdoc.html").include?('Ruby on Rails 4.0.1')

        assert_exists "#{tag}/guides/output/index.html"
        assert_exists "#{tag}/guides/output/index.html.gz"
        assert_exists "#{tag}/guides/output/kindle/ruby_on_rails_guides_#{tag}.mobi"

        assert File.read("#{tag}/guides/output/index.html").include?("Ruby on Rails Guides (#{tag})")

        #
        # --- Symlinks -----------------------------------------------------------
        #

        assert_equal 'v4.0.1', File.readlink('api/stable')
        assert_equal 'v4.0.1', File.readlink('guides/stable')

        assert_equal File.expand_path('v3.2.15/doc/rdoc'), File.readlink('api/v3.2.15')
        assert_equal File.expand_path('v3.2.15/railties/guides/output'), File.readlink('guides/v3.2.15')

        assert_equal File.expand_path('v4.0.0/doc/rdoc'), File.readlink('api/v4.0.0')
        assert_equal File.expand_path('v4.0.0/guides/output'), File.readlink('guides/v4.0.0')

        assert_equal File.expand_path('v4.0.1/doc/rdoc'), File.readlink('api/v4.0.1')
        assert_equal File.expand_path('v4.0.1/guides/output'), File.readlink('guides/v4.0.1')


        #
        # --- Edge ---------------------------------------------------------------
        #

        assert_exists 'master/doc/rdoc/index.html'
        assert_exists 'master/doc/rdoc/index.html.gz'
        assert_exists 'master/doc/rdoc/edge_badge.png'

        html = File.read('master/doc/rdoc/files/railties/RDOC_MAIN_rdoc.html')
        assert html.include?("Ruby on Rails master@#{git_manager.short_sha1}")
        assert html.include?('<img src="/edge_badge.png"')

        assert !File.read('master/doc/rdoc/panel/index.html').include?('edge_badge.png')

        assert_exists 'master/guides/output/index.html'
        assert_exists 'master/guides/output/index.html.gz'
        assert_exists "master/guides/output/kindle/ruby_on_rails_guides_#{git_manager.short_sha1}.mobi"

        assert_equal File.expand_path('master/doc/rdoc'), File.readlink('api/edge')
        assert_equal File.expand_path('master/guides/output'), File.readlink('guides/edge')

        html = File.read('master/guides/output/index.html')
        assert html.include?("Ruby on Rails Guides (#{git_manager.short_sha1})")
        assert html.include?('<img src="images/edge_badge.png"')
      end
    end
  end
end
