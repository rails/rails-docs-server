require_relative 'test_helper'

require 'version_number'

class VersionNumberTest < Minitest::Test
  def test_initialize_tag
    assert_version [3, 2, 0, 0], VersionNumber.new('v3.2.0')
    assert_version [5, 0, 0, 1], VersionNumber.new('v5.0.0.1')
  end

  def test_initialize_string
    assert_version [4, 0, 0, 0], VersionNumber.new('4')
    assert_version [4, 2, 0, 0], VersionNumber.new('4.2')
    assert_version [4, 2, 7, 0], VersionNumber.new('4.2.7')
    assert_version [4, 2, 7, 1], VersionNumber.new('4.2.7.1')
  end

  def test_diamond_with_version_object
    assert VersionNumber.new('3.2')   < VersionNumber.new('5.0')
    assert VersionNumber.new('4')     < VersionNumber.new('4.0.0.1')
    assert VersionNumber.new('4.2')   < VersionNumber.new('4.10')
    assert VersionNumber.new('4.2.1') < VersionNumber.new('4.2.2')
  end

  def test_diamond_with_string
    assert VersionNumber.new('3.2')   < '5.0'
    assert VersionNumber.new('4')     < '4.0.0.1'
    assert VersionNumber.new('4.2')   < '4.10'
    assert VersionNumber.new('4.2.1') < '4.2.2'
  end

  def assert_version(expected_parts, version)
    assert_equal expected_parts, version.parts
  end
end
