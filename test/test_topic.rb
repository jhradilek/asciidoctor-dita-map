require 'minitest/autorun'
require 'minitest/mock'
require_relative '../lib/dita-map/topic'

class TopicTest < Minitest::Test
  def test_topic_structure
    adoc  = <<~EOF.chomp
    :_mod-docs-content-type: CONCEPT

    = A topic title
    EOF

    topic = AsciidoctorDitaMap::Topic.new adoc

    assert_equal 'A topic title', topic.title
    assert_equal 'concept', topic.type
  end

  def test_topic_with_attributes
    adoc  = <<~EOF.chomp
    :_mod-docs-content-type: CONCEPT

    = A {module} title
    EOF

    topic = AsciidoctorDitaMap::Topic.new adoc, ['module=topic']

    assert_equal 'A topic title', topic.title
    assert_equal 'concept', topic.type
  end

  def test_topic_no_input
    adoc  = ''

    topic = AsciidoctorDitaMap::Topic.new adoc

    assert_nil topic.title
    assert_nil topic.type
  end

  def test_topic_no_title
    adoc  = <<~EOF.chomp
    :_mod-docs-content-type: CONCEPT
    EOF

    topic = AsciidoctorDitaMap::Topic.new adoc

    assert_nil topic.title
  end

  def test_topic_no_type
    adoc  = <<~EOF.chomp
    = A topic title
    EOF

    topic = AsciidoctorDitaMap::Topic.new adoc

    assert_nil topic.type
  end

  def test_topic_invalid_type
    adoc  = <<~EOF.chomp
    :_mod-docs-content-type: UNKNOWN
    EOF

    topic = AsciidoctorDitaMap::Topic.new adoc

    assert_nil topic.type
  end

  def test_topic_content_type
    adoc  = <<~EOF.chomp
    :_content-type: CONCEPT
    EOF

    topic = AsciidoctorDitaMap::Topic.new adoc

    assert_equal 'concept', topic.type
  end

  def test_topic_module_type
    adoc  = <<~EOF.chomp
    :_module-type: CONCEPT
    EOF

    topic = AsciidoctorDitaMap::Topic.new adoc

    assert_equal 'concept', topic.type
  end

  def test_topic_assembly
    adoc  = <<~EOF.chomp
    :_mod-docs-content-type: ASSEMBLY
    EOF

    topic = AsciidoctorDitaMap::Topic.new adoc

    assert_equal 'assembly', topic.type
  end

  def test_topic_procedure
    adoc  = <<~EOF.chomp
    :_mod-docs-content-type: PROCEDURE
    EOF

    topic = AsciidoctorDitaMap::Topic.new adoc

    assert_equal 'task', topic.type
  end

  def test_topic_reference
    adoc  = <<~EOF.chomp
    :_mod-docs-content-type: REFERENCE
    EOF

    topic = AsciidoctorDitaMap::Topic.new adoc

    assert_equal 'reference', topic.type
  end

  def test_topic_map
    adoc  = <<~EOF.chomp
    :_mod-docs-content-type: MAP
    EOF

    topic = AsciidoctorDitaMap::Topic.new adoc

    assert_equal 'map', topic.type
  end

  def test_topic_attributes
    adoc  = <<~EOF.chomp
    :_mod-docs-content-type: ATTRIBUTES
    EOF

    topic = AsciidoctorDitaMap::Topic.new adoc

    assert_equal 'attributes', topic.type
  end

  def test_topic_snippet
    adoc  = <<~EOF.chomp
    :_mod-docs-content-type: SNIPPET
    EOF

    topic = AsciidoctorDitaMap::Topic.new adoc

    assert_equal 'snippet', topic.type
  end

  def test_topic_ignore
    adoc  = <<~EOF.chomp
    :_mod-docs-content-type: IGNORE
    EOF

    topic = AsciidoctorDitaMap::Topic.new adoc

    assert_equal 'ignore', topic.type
  end
end
