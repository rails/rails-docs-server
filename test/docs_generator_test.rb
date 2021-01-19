# Pending.

__END__

require_relative 'test_helper'

require 'docs_generator'
require 'git_manager'
require 'logging'
require 'generators/release'

class DocsGeneratorTest < Minitest::Test
  def test_series
    release_directories = %w(v3.1.2 v3.1.0 v4.2.1 v4.2.7 v5.0.0)
    expected_series = {
      'v3.1'   => 'v3.1.2',
      'v4.2'   => 'v4.2.7',
      'v5.0'   => 'v5.0.0',
      'stable' => 'v5.0.0', # stable, given the existing directories
    }

    in_tmpdir do
      mkdir 'basedir'

      Dir.chdir('basedir') do
        release_directories.each {|rd| mkdir rd}
      end

      actual_series = DocsGenerator.new('basedir').series
      assert_equal expected_series, actual_series
    end
  end

  def test_release_directories
    expected_release_directories = %w(v4.0.1 v4.1.7 v4.11.2 v3.1.2)

    in_tmpdir do
      mkdir 'basedir'

      Dir.chdir('basedir') do
        mkdir 'bin'
        mkdir '.ssh'

        expected_release_directories.each {|rd| mkdir rd}
      end

      actual_release_directories = DocsGenerator.new('basedir').release_directories
      assert_equal expected_release_directories.sort, actual_release_directories.sort
    end
  end

  def test_max_tag
    docs_generator = DocsGenerator.new('.')

    assert_equal 'v4.0.0.1', docs_generator.max_tag(%w(v2.3.0 v4.0.0 v3.0.4 v3.1.2 v4.0.0.1 v3.2.8))
  end

  def test_generates_docs
    skip 'skipping docs generation, execute test:all (these take a lot of time)' unless ENV['TEST_DOCS_GENERATION']

    release_tags = %w(v3.2.15 v4.0.0 v4.0.1 v4.2.8 v4.2.9 v5.0.0)

    in_tmpdir do
      mkdir 'basedir'

      git_manager = GitManager.new('basedir')
      git_manager.update_main

      mkdir_p 'main/doc/rdoc'

      html_orphan = 'main/doc/rdoc/orphan.html'
      touch html_orphan
      assert_exists html_orphan # ensure the setup is correct to prevent a false positive later

      html_gz_orphan = 'main/doc/rdoc/orphan.html.gz'
      touch html_gz_orphan
      assert_exists html_gz_orphan # ensure the setup is correct to prevent a false positive later

      git_manager.stub(:release_tags, release_tags) do
        docs_generator = DocsGenerator.new('basedir', git_manager)
        docs_generator.generate
      end

      #
      # --- Realeases ----------------------------------------------------------
      #

      Dir.chdir('basedir') do
        release_tags.each do |tag|
          assert_generated_docs(tag)
          assert_symlinks(tag)
        end

        #
        # --- Symlinks -----------------------------------------------------------
        #

        assert_equal 'v3.2.15', File.readlink('api/v3.2')
        assert_equal 'v3.2.15', File.readlink('guides/v3.2')

        assert_equal 'v4.0.1', File.readlink('api/v4.0')
        assert_equal 'v4.0.1', File.readlink('guides/v4.0')

        assert_equal 'v4.2.9', File.readlink('api/v4.2')
        assert_equal 'v4.2.9', File.readlink('guides/v4.2')

        assert_equal 'v5.0.0', File.readlink('api/v5.0')
        assert_equal 'v5.0.0', File.readlink('guides/v5.0')

        assert_equal 'v5.0.0', File.readlink('api/stable')
        assert_equal 'v5.0.0', File.readlink('guides/stable')

        #
        # --- Edge ---------------------------------------------------------------
        #

        assert_exists 'main/doc/rdoc/index.html'
        assert_exists 'main/doc/rdoc/index.html.gz'
        assert_exists 'main/doc/rdoc/edge_badge.png'

        html = File.read('main/doc/rdoc/files/railties/RDOC_MAIN_rdoc.html')
        assert html.include?("Ruby on Rails main@#{git_manager.short_sha1}")
        assert html.include?('<img src="/edge_badge.png"')

        assert !File.read('main/doc/rdoc/panel/index.html').include?('edge_badge.png')

        assert_exists 'main/guides/output/index.html'
        assert_exists 'main/guides/output/index.html.gz'
        refute_exists "main/guides/output/kindle/ruby_on_rails_guides_#{git_manager.short_sha1}.mobi"

        assert_equal File.expand_path('main/doc/rdoc'), File.readlink('api/edge')
        assert_equal File.expand_path('main/guides/output'), File.readlink('guides/edge')

        html = File.read('main/guides/output/index.html')
        assert html.include?("Ruby on Rails Guides (#{git_manager.short_sha1})")
        assert html.include?('<img src="images/edge_badge.png"')

        refute_exists html_orphan
        refute_exists html_gz_orphan
      end
    end
  end

  def assert_generated_docs(tag)
    assert_generated_api(tag)
    assert_generated_guides(tag)
  end

  def assert_generated_api(tag)
    output = Generators::Release.new(tag, tag).api_output

    assert_exists "#{output}/index.html"
    assert_exists "#{output}/index.html.gz"

    version = VersionNumber.new(tag)

    main = if version < '4'
      "#{output}/files/RDOC_MAIN_rdoc.html"
    else
      "#{output}/files/railties/RDOC_MAIN_rdoc.html"
    end

    header = if version < '4.0.1'
      "Ruby on Rails #{tag}"
    else
      # In 4.0.1 the API dropped the leading "v".
      "Ruby on Rails #{tag[1..-1]}"
    end

    assert File.read(main).include?(header)
  end

  def assert_generated_guides(tag)
    output = Generators::Release.new(tag, tag).guides_output

    assert_exists "#{output}/index.html"
    assert_exists "#{output}/index.html.gz"
    assert_exists "#{output}/kindle/ruby_on_rails_guides_#{tag}.mobi"

    assert File.read("#{output}/index.html").include?("Ruby on Rails Guides (#{tag})")
  end

  def assert_symlinks(tag)
    generator = Generators::Release.new(tag, tag)

    assert_equal generator.api_output, File.readlink("api/#{tag}")
    assert_equal generator.guides_output, File.readlink("guides/#{tag}")
  end
end
