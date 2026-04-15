require 'minitest/autorun'
require_relative '../lib/dita-map/version'

class VersionTest < Minitest::Test
  def test_version
    assert_match(/^\d+\.\d+\.\d+$/, AsciidoctorDitaMap::VERSION)
  end
end
