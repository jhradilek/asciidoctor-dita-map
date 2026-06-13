require 'minitest/autorun'
require 'minitest/mock'
require 'ostruct'
require 'pathname'
require_relative 'helper'
require_relative '../lib/dita-map/convert'

class CliTest < Minitest::Test
  def test_defaults
    conv = AsciidoctorDitaMap::Convert.new
    attr = conv.instance_variable_get :@attr
    opts = conv.instance_variable_get :@opts
    prep = conv.instance_variable_get :@prep

    assert_equal false, opts[:self]
    assert_equal false, opts[:verbose]
    assert_equal false, opts[:zero_offset]
    assert_equal true, opts[:chunk]
    assert_equal true, opts[:id]
    assert_equal true, opts[:locktitle]
    assert_equal true, opts[:navtitle]
    assert_equal true, opts[:title]
    assert_equal true, opts[:toc]
    assert_equal true, opts[:type]
    assert_equal [], attr
    assert_equal '', prep
  end

  def test_run_id
    conv = AsciidoctorDitaMap::Convert.new
    mock = OpenStruct.new(:title => 'A map title', :type => nil, :id => 'map-id', :includes => [])

    AsciidoctorDitaMap::Map.stub :new, mock do
      xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

      assert_xpath_equal xml, 'map-id', '/map/@id'
    end
  end

  def test_run_no_id
    conv = AsciidoctorDitaMap::Convert.new
    mock = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => [])

    AsciidoctorDitaMap::Map.stub :new, mock do
      xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

      assert_xpath_count xml, 0, '/map/@id'
    end
  end

  def test_run_title
    conv = AsciidoctorDitaMap::Convert.new
    mock = OpenStruct.new(:title => 'A map title', :type => nil, :id => nil, :includes => [])

    AsciidoctorDitaMap::Map.stub :new, mock do
      xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

      assert_xpath_equal xml, 'A map title', '/map/title/text()'
    end
  end

  def test_run_no_title
    conv = AsciidoctorDitaMap::Convert.new
    mock = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => [])

    AsciidoctorDitaMap::Map.stub :new, mock do
      xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

      assert_xpath_count xml, 0, '/map/title'
    end
  end

  def test_run_title_entities
    conv = AsciidoctorDitaMap::Convert.new
    mock = OpenStruct.new(:title => 'A&#160;map title', :type => nil, :id => nil, :includes => [])

    AsciidoctorDitaMap::Map.stub :new, mock do
      xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

      assert_xpath_equal xml, 'A&#160;map title', '/map/title/text()'
    end
  end

  def test_run_topicref
    conv = AsciidoctorDitaMap::Convert.new
    incl = [
      { :target => 'file.adoc', :offset => 1 }
    ]
    mock_map   = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => incl)
    mock_topic = OpenStruct.new(:title => 'A topic title', :type => 'concept')

    File.stub :read, 'topic contents' do
      AsciidoctorDitaMap::Map.stub :new, mock_map do
        AsciidoctorDitaMap::Topic.stub :new, mock_topic do
          xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

          assert_xpath_count xml, 1, '//topicref'
          assert_xpath_count xml, 0, '//mapref'
          assert_xpath_equal xml, 'file.dita', '/map/topicref/@href'
          assert_xpath_equal xml, 'A topic title', '/map/topicref/@navtitle'
          assert_xpath_equal xml, 'yes', '/map/topicref/@locktitle'
          assert_xpath_equal xml, 'concept', '/map/topicref/@type'
        end
      end
    end
  end

  def test_run_mapref
    conv = AsciidoctorDitaMap::Convert.new
    incl = [
      { :target => 'file.adoc', :offset => 1 }
    ]
    mock_map   = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => incl)
    mock_topic = OpenStruct.new(:title => 'A map title', :type => 'map')

    File.stub :read, 'topic contents' do
      AsciidoctorDitaMap::Map.stub :new, mock_map do
        AsciidoctorDitaMap::Topic.stub :new, mock_topic do
          xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

          assert_xpath_count xml, 1, '//mapref'
          assert_xpath_count xml, 0, '//topicref'
          assert_xpath_equal xml, 'file.ditamap', '/map/mapref/@href'
          assert_xpath_equal xml, 'ditamap', '/map/mapref/@format'
          assert_xpath_equal xml, 'map', '/map/mapref/@type'
        end
      end
    end
  end

  def test_run_attributes
    conv = AsciidoctorDitaMap::Convert.new
    incl = [
      { :target => 'file.adoc', :offset => 1 }
    ]
    mock_map   = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => incl)
    mock_topic = OpenStruct.new(:title => nil, :type => 'attributes')

    File.stub :read, 'topic contents' do
      AsciidoctorDitaMap::Map.stub :new, mock_map do
        AsciidoctorDitaMap::Topic.stub :new, mock_topic do
          xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

          assert_xpath_count xml, 0, '//mapref'
          assert_xpath_count xml, 0, '//topicref'
        end
      end
    end
  end

  def test_run_nesting
    conv = AsciidoctorDitaMap::Convert.new
    incl = [
      { :target => 'file-1.adoc', :offset => 1 },
      { :target => 'file-2.adoc', :offset => 2 },
      { :target => 'file-3.adoc', :offset => 3 },
      { :target => 'file-4.adoc', :offset => 2 },
      { :target => 'file-5.adoc', :offset => 1 }
    ]
    mock_map   = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => incl)
    mock_topic = OpenStruct.new(:title => 'A topic title', :type => 'concept')

    File.stub :read, 'topic contents' do
      AsciidoctorDitaMap::Map.stub :new, mock_map do
        AsciidoctorDitaMap::Topic.stub :new, mock_topic do
          xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

          assert_xpath_equal xml, 'file-1.dita', '/map/topicref[1]/@href'
          assert_xpath_equal xml, 'file-2.dita', '/map/topicref[1]/topicref[1]/@href'
          assert_xpath_equal xml, 'file-3.dita', '/map/topicref[1]/topicref[1]/topicref/@href'
          assert_xpath_equal xml, 'file-4.dita', '/map/topicref[1]/topicref[2]/@href'
          assert_xpath_equal xml, 'file-5.dita', '/map/topicref[2]/@href'
        end
      end
    end
  end

  def test_run_invalid_leveloffset
    conv = AsciidoctorDitaMap::Convert.new
    incl = [
      { :target => 'file-1.adoc', :offset => 3 },
      { :target => 'file-2.adoc', :offset => 4 },
      { :target => 'file-3.adoc', :offset => 5 },
      { :target => 'file-4.adoc', :offset => 4 },
      { :target => 'file-5.adoc', :offset => 2 }
    ]
    mock_map   = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => incl)
    mock_topic = OpenStruct.new(:title => 'A topic title', :type => 'concept')

    File.stub :read, 'topic contents' do
      AsciidoctorDitaMap::Map.stub :new, mock_map do
        AsciidoctorDitaMap::Topic.stub :new, mock_topic do
          assert_output(nil, /invalid leveloffset/) do
            xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

            assert_xpath_equal xml, 'file-1.dita', '/map/topicref[1]/@href'
            assert_xpath_equal xml, 'file-2.dita', '/map/topicref[1]/topicref[1]/@href'
            assert_xpath_equal xml, 'file-3.dita', '/map/topicref[1]/topicref[1]/topicref/@href'
            assert_xpath_equal xml, 'file-4.dita', '/map/topicref[1]/topicref[2]/@href'
            assert_xpath_equal xml, 'file-5.dita', '/map/topicref[2]/@href'
          end
        end
      end
    end
  end

  def test_run_zero_offset
    conv = AsciidoctorDitaMap::Convert.new
    incl = [
      { :target => 'file-1.adoc', :offset => 0 },
      { :target => 'file-2.adoc', :offset => 1 }
    ]
    mock_map   = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => incl)
    mock_topic = OpenStruct.new(:title => 'A topic title', :type => 'concept')

    File.stub :read, 'topic contents' do
      AsciidoctorDitaMap::Map.stub :new, mock_map do
        AsciidoctorDitaMap::Topic.stub :new, mock_topic do
          assert_output(nil, /invalid leveloffset/) do
            xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

            assert_xpath_equal xml, 'file-1.dita', '/map/topicref[1]/@href'
            assert_xpath_equal xml, 'file-2.dita', '/map/topicref[2]/@href'
          end
        end
      end
    end
  end

  def test_run_chunking
    conv = AsciidoctorDitaMap::Convert.new
    incl = [
      { :target => 'file-1.adoc', :offset => 1, :chunk => 'to-content' },
      { :target => 'file-2.adoc', :offset => 2 },
      { :target => 'file-3.adoc', :offset => 1 }
    ]
    mock_map   = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => incl)
    mock_topic = OpenStruct.new(:title => 'A topic title', :type => 'concept')

    File.stub :read, 'topic contents' do
      AsciidoctorDitaMap::Map.stub :new, mock_map do
        AsciidoctorDitaMap::Topic.stub :new, mock_topic do
          xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

          assert_xpath_equal xml, 'to-content',  '/map/topicref[1]/@chunk'
          assert_xpath_count xml, 0, '/map/topicref[1]/topicref[1]/@chunk'
          assert_xpath_count xml, 0, '/map/topicref[2]/@chunk'
        end
      end
    end
  end

  def test_run_toc
    conv = AsciidoctorDitaMap::Convert.new
    incl = [
      { :target => 'file-1.adoc', :offset => 1 },
      { :target => 'file-2.adoc', :offset => 2, :toc => 'no' },
      { :target => 'file-3.adoc', :offset => 1 }
    ]
    mock_map   = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => incl)
    mock_topic = OpenStruct.new(:title => 'A topic title', :type => 'concept')

    File.stub :read, 'topic contents' do
      AsciidoctorDitaMap::Map.stub :new, mock_map do
        AsciidoctorDitaMap::Topic.stub :new, mock_topic do
          xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

          assert_xpath_equal xml, 'no',  '/map/topicref[1]/topicref[1]/@toc'
          assert_xpath_count xml, 0, '/map/topicref[1]/@toc'
          assert_xpath_count xml, 0, '/map/topicref[2]/@toc'
        end
      end
    end
  end
end
