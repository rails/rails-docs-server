require 'test_helper'
require 'generators/release'

class Generators::ReleaseTest < Minitest::Test

  def in_release(tag)
    in_tmpdir do
      cp_r("#{fixtures_directory}/releases/#{tag}", '.')
      generator = Generators::Release.new(tag, Dir.pwd)
      Dir.chdir(tag) do
        generator.before_generation
        yield generator
      end
    end
  end

  def assert_patched(filename)
    assert cmp(filename, "#{filename}.expected"), "incorrect patch:\n#{`diff #{filename} #{filename}.expected`}"
  end

  def assert_deleted(filename)
    refute File.exist?(filename), "#{filename} exists"
  end

  def test_before_generation_v4_2_10
    in_release 'v4.2.10' do
      assert_deleted 'Gemfile.lock'
      assert_patched 'Gemfile'
    end
  end

  def test_before_generation_v6_1_7_5
    in_release 'v6.1.7.5' do
      assert_patched 'Gemfile'
    end
  end

  def test_before_generation_v5_1_2_to_v5_1_4
    %w(v5.1.2 v5.1.3 v5.1.4).each do |tag|
      in_release(tag) do
        assert_patched 'guides/source/documents.yaml'
      end
    end
  end

  def test_before_generation_v8_0_3
    in_release 'v8.0.3' do
      assert_patched 'Gemfile'
      assert_patched 'guides/assets/stylesrc/components/_code-container.scss'
    end
  end
end
