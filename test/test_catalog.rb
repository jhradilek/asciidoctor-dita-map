require 'minitest/autorun'
require_relative '../lib/dita-map/catalog'

class CatalogTest < Minitest::Test
  def test_catalog
    adoc = <<~EOF.chomp
    = A map title

    include::file_1.adoc[]
    include::file_2.adoc[leveloffset=+1,chunk="to-content"]
    include::file_3.adoc[leveloffset=+2,toc="no"]
    include::file_4.adoc[leveloffset=+1,navtitle="A topic title"]
    EOF

    Asciidoctor::Extensions.register do
      include_processor CatalogIncludeDirectives
    end

    doc = Asciidoctor.load adoc, safe: :safe, logger: false, catalog_assets: true

    assert doc.catalog.has_key? :include_files
    assert_equal doc.catalog[:include_files][0], { :target => 'file_1.adoc', :offset => 0, :chunk => nil,          :toc => nil,  :navtitle => nil }
    assert_equal doc.catalog[:include_files][1], { :target => 'file_2.adoc', :offset => 1, :chunk => 'to-content', :toc => nil,  :navtitle => nil }
    assert_equal doc.catalog[:include_files][2], { :target => 'file_3.adoc', :offset => 2, :chunk => nil,          :toc => 'no', :navtitle => nil }
    assert_equal doc.catalog[:include_files][3], { :target => 'file_4.adoc', :offset => 1, :chunk => nil,          :toc => nil,  :navtitle => 'A topic title' }
  end

  def test_catalog_empty
    adoc = <<~EOF.chomp
    = A map title

    No include directives present.
    EOF

    Asciidoctor::Extensions.register do
      include_processor CatalogIncludeDirectives
    end

    doc = Asciidoctor.load adoc, safe: :safe, logger: false, catalog_assets: true

    assert_nil doc.catalog[:include_files]
  end

  def test_catalog_supported_file_extensions
    adoc = <<~EOF.chomp
    = A map title

    include::file.ad[]
    include::file.adoc[]
    include::file.asc[]
    include::file.asciidoc[]
    EOF

    Asciidoctor::Extensions.register do
      include_processor CatalogIncludeDirectives
    end

    doc = Asciidoctor.load adoc, safe: :safe, logger: false, catalog_assets: true

    assert_equal doc.catalog[:include_files].length, 4
  end

  def test_catalog_unsupported_file_extensions
    adoc = <<~EOF.chomp
    = A map title

    include::file.ascii[]
    include::file.md[]
    include::file.txt[]
    include::file.yml[]
    EOF

    Asciidoctor::Extensions.register do
      include_processor CatalogIncludeDirectives
    end

    doc = Asciidoctor.load adoc, safe: :safe, logger: false, catalog_assets: true

    assert_nil doc.catalog[:include_files]
  end
end
