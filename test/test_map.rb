require 'minitest/autorun'
require 'minitest/mock'
require_relative '../lib/dita-map/map'

class MapTest < Minitest::Test
  def test_map_structure
    adoc = <<~EOF.chomp
    :chunk-to-content:
    :navtitle: A custom title

    [id="map-id"]
    = A map title

    include::file-1.adoc[leveloffset=+1]
    include::file-2.adoc[leveloffset=+2]
    EOF

    map = AsciidoctorDitaMap::Map.new adoc, Pathname.new(Dir.pwd).expand_path

    assert_equal 'map-id', map.id
    assert_equal 'A map title', map.title
    assert_equal 'A custom title', map.navtitle
    assert_equal true, map.chunk
    assert_equal map.includes[0][:target], 'file-1.adoc'
    assert_equal map.includes[0][:offset], 1
    assert_equal map.includes[1][:target], 'file-2.adoc'
    assert_equal map.includes[1][:offset], 2
  end

  def test_map_with_attributes
    adoc = <<~EOF.chomp
    [id="{module}-id"]
    = A {module} title
    EOF

    map = AsciidoctorDitaMap::Map.new adoc, Pathname.new(Dir.pwd).expand_path, ['module=map']

    assert_equal 'map-id', map.id
    assert_equal 'A map title', map.title
  end

  def test_map_no_includes
    adoc = <<~EOF.chomp
    [id="map-id"]
    = A map title
    EOF

    map = AsciidoctorDitaMap::Map.new adoc, Pathname.new(Dir.pwd).expand_path

    assert_empty map.includes
  end

  def test_map_no_id
    adoc = <<~EOF.chomp
    = A map title
    EOF

    map = AsciidoctorDitaMap::Map.new adoc, Pathname.new(Dir.pwd).expand_path

    assert_nil map.id
  end

  def test_map_no_title
    adoc = <<~EOF.chomp
    include::file-1.adoc[leveloffset=+1]
    include::file-2.adoc[leveloffset=+2]
    EOF

    map = AsciidoctorDitaMap::Map.new adoc, Pathname.new(Dir.pwd).expand_path

    assert_nil map.title
  end

  def test_map_no_chunk
    adoc = <<~EOF.chomp
    = A map title
    EOF

    map = AsciidoctorDitaMap::Map.new adoc, Pathname.new(Dir.pwd).expand_path
    assert_equal false, map.chunk
  end

  def test_map_no_navtitle
    adoc = <<~EOF.chomp
    = A map title
    EOF

    map = AsciidoctorDitaMap::Map.new adoc, Pathname.new(Dir.pwd).expand_path
    assert_nil map.navtitle
  end
end
