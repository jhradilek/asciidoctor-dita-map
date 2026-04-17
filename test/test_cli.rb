require 'minitest/autorun'
require 'minitest/mock'
require 'pathname'
require_relative 'helper'
require_relative '../lib/dita-map/cli'

class CliTest < Minitest::Test
  def test_defaults
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', []
    attr = cli.instance_variable_get :@attr
    opts = cli.instance_variable_get :@opts
    prep = cli.instance_variable_get :@prep

    assert_equal false, opts[:output]
    assert_equal true, opts[:id]
    assert_equal true, opts[:navtitle]
    assert_equal true, opts[:type]
    assert_equal [], attr
    assert_equal [], prep
  end

  def test_missing_file
    file = 'file.adoc'

    File.stub :exist?, false do
      File.stub :file?, true do
        error = assert_raises OptionParser::InvalidArgument do
          AsciidoctorDitaMap::Cli.new 'script-name', [file]
        end

        assert_match(/not a file: #{file}/, error.message)
      end
    end
  end

  def test_not_a_file
    file = 'file.adoc'

    File.stub :exist?, true do
      File.stub :file?, false do
        error = assert_raises OptionParser::InvalidArgument do
          AsciidoctorDitaMap::Cli.new 'script-name', [file]
        end

        assert_match(/not a file: #{file}/, error.message)
      end
    end
  end

  def test_file_not_readable
    file = 'file.adoc'

    File.stub :exist?, true do
      File.stub :file?, true do
        File.stub :readable?, false do
          error = assert_raises OptionParser::InvalidArgument do
            AsciidoctorDitaMap::Cli.new 'script-name', [file]
          end

          assert_match(/file not readable: #{file}/, error.message)
        end
      end
    end
  end

  def test_out_file_short
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['-o', 'file.dita']
    opts = cli.instance_variable_get :@opts

    assert_equal 'file.dita', opts[:output]
  end

  def test_out_file_long
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['--out-file', 'file.dita']
    opts = cli.instance_variable_get :@opts

    assert_equal 'file.dita', opts[:output]
  end

  def test_out_file_stdout
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['-o', '-']
    opts = cli.instance_variable_get :@opts

    assert_equal $stdout, opts[:output]
  end

  def test_attribute_short
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['-a', 'version=3']
    assert_includes cli.instance_variable_get(:@attr), 'version=3'
  end

  def test_attribute_long
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['--attribute', 'version=3']
    assert_includes cli.instance_variable_get(:@attr), 'version=3'
  end

  def test_attribute_multiple
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['-a', 'version=3', '-a', 'release=1']
    attr = cli.instance_variable_get :@attr

    assert_includes attr, 'version=3'
    assert_includes attr, 'release=1'
  end

  def test_prepend_file_short
    file = 'attributes.adoc'

    File.stub :exist?, true do
      File.stub :file?, true do
        File.stub :readable?, true do
          cli = AsciidoctorDitaMap::Cli.new 'script-name', ['-p', file]
          assert_includes cli.instance_variable_get(:@prep), file
        end
      end
    end
  end

  def test_prepend_file_long
    file= 'attributes.adoc'

    File.stub :exist?, true do
      File.stub :file?, true do
        File.stub :readable?, true do
          cli = AsciidoctorDitaMap::Cli.new 'script-name', ['--prepend-file', file]
          assert_includes cli.instance_variable_get(:@prep), file
        end
      end
    end
  end

  def test_prepend_file_multiple
    first  = 'common-attributes.adoc'
    second = 'custom-attributes.adoc'

    File.stub :exist?, true do
      File.stub :file?, true do
        File.stub :readable?, true do
          cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['-p', first, '-p', second]
          prep = cli.instance_variable_get(:@prep)

          assert_includes prep, first
          assert_includes prep, second
        end
      end
    end
  end

  def test_prepend_file_missing_file
    file = 'attributes.adoc'

    File.stub :exist?, false do
      File.stub :file?, true do
        error = assert_raises OptionParser::InvalidArgument do
          AsciidoctorDitaMap::Cli.new 'script-name', ['-p', file]
        end

        assert_match(/not a file: #{file}/, error.message)
      end
    end
  end

  def test_prepend_file_not_a_file
    file = 'attributes.adoc'

    File.stub :exist?, true do
      File.stub :file?, false do
        error = assert_raises OptionParser::InvalidArgument do
          AsciidoctorDitaMap::Cli.new 'script-name', ['-p', file]
        end

        assert_match(/not a file: #{file}/, error.message)
      end
    end
  end

  def test_prepend_file_not_readable
    file = 'attributes.adoc'

    File.stub :exist?, true do
      File.stub :file?, true do
        File.stub :readable?, false do
          error = assert_raises OptionParser::InvalidArgument do
            AsciidoctorDitaMap::Cli.new 'script-name', ['-p', file]
          end

          assert_match(/file not readable: #{file}/, error.message)
        end
      end
    end
  end

  def test_no_id_short
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['-I']
    opts = cli.instance_variable_get :@opts

    assert_equal false, opts[:id]
  end

  def test_no_id_long
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['--no-id']
    opts = cli.instance_variable_get :@opts

    assert_equal false, opts[:id]
  end

  def test_no_id_output
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['--no-id']

    cli.stub :parse_map, [[], nil, 'map-id'] do
      xml = cli.convert_map 'map contents', Pathname.new(Dir.pwd).expand_path

      assert_xpath_count xml, 0, '/map/@id'
    end
  end

  def test_no_navtitle_short
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['-N']
    opts = cli.instance_variable_get :@opts

    assert_equal false, opts[:navtitle]
  end

  def test_no_navtitle_long
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['--no-navtitle']
    opts = cli.instance_variable_get :@opts

    assert_equal false, opts[:navtitle]
  end

  def test_no_navtitle_output
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['--no-navtitle']

    File.stub :read, 'topic contents' do
      cli.stub :parse_map, [[{ :target => 'file.adoc', :offset => 1 }]] do
        cli.stub :parse_topic, ['A topic title', 'concept'] do
          xml = cli.convert_map 'map contents', Pathname.new(Dir.pwd).expand_path

          assert_xpath_count xml, 0, '//topicref/@navtitle'
        end
      end
    end
  end

  def test_no_type_short
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['-T']
    opts = cli.instance_variable_get :@opts

    assert_equal false, opts[:type]
  end

  def test_no_type_long
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['--no-type']
    opts = cli.instance_variable_get :@opts

    assert_equal false, opts[:type]
  end

  def test_no_type_output
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['--no-type']

    File.stub :read, 'topic contents' do
      cli.stub :parse_map, [[{ :target => 'file.adoc', :offset => 1 }]] do
        cli.stub :parse_topic, ['A topic title', 'concept'] do
          xml = cli.convert_map 'map contents', Pathname.new(Dir.pwd).expand_path

          assert_xpath_count xml, 0, '//topicref/@type'
        end
      end
    end
  end

  def test_help_short
    assert_output(/^Usage: script-name /) do
      error = assert_raises SystemExit do
        AsciidoctorDitaMap::Cli.new 'script-name', ['-h']
      end

      assert_equal 0, error.status
    end
  end

  def test_help_long
    assert_output(/^Usage: script-name /) do
      error = assert_raises SystemExit do
        AsciidoctorDitaMap::Cli.new 'script-name', ['--help']
      end

      assert_equal 0, error.status
    end
  end

  def test_version_short
    assert_output(/^script-name \d+\.\d+\.\d+$/) do
      error = assert_raises SystemExit do
        AsciidoctorDitaMap::Cli.new 'script-name', ['-v']
      end

      assert_equal 0, error.status
    end
  end

  def test_version_long
    assert_output(/^script-name \d+\.\d+\.\d+$/) do
      error = assert_raises SystemExit do
        AsciidoctorDitaMap::Cli.new 'script-name', ['--version']
      end

      assert_equal 0, error.status
    end
  end

  def test_convert_map_id
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', []

    cli.stub :parse_map, [[], 'A map title', 'map-id'] do
      xml = cli.convert_map 'map contents', Pathname.new(Dir.pwd).expand_path

      assert_xpath_equal xml, 'map-id', '/map/@id'
    end
  end

  def test_convert_map_no_id
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', []

    cli.stub :parse_map, [[], 'A map title', nil] do
      xml = cli.convert_map 'map contents', Pathname.new(Dir.pwd).expand_path

      assert_xpath_count xml, 0, '/map/@id'
    end
  end

  def test_convert_map_title
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', []

    cli.stub :parse_map, [[], 'A map title'] do
      xml = cli.convert_map 'map contents', Pathname.new(Dir.pwd).expand_path

      assert_xpath_equal xml, 'A map title', '/map/title/text()'
    end
  end

  def test_convert_map_no_title
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', []

    cli.stub :parse_map, [[], nil] do
      xml = cli.convert_map 'map contents', Pathname.new(Dir.pwd).expand_path

      assert_xpath_count xml, 0, '/map/title'
    end
  end

  def test_convert_map_topicref
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', []

    File.stub :read, 'topic contents' do
      cli.stub :parse_map, [[{ :target => 'file.adoc', :offset => 1 }]] do
        cli.stub :parse_topic, ['A topic title', 'concept'] do
          xml = cli.convert_map 'map contents', Pathname.new(Dir.pwd).expand_path

          assert_xpath_count xml, 1, '//topicref'
          assert_xpath_count xml, 0, '//mapref'
          assert_xpath_equal xml, 'file.dita', '/map/topicref/@href'
          assert_xpath_equal xml, 'A topic title', '/map/topicref/@navtitle'
          assert_xpath_equal xml, 'concept', '/map/topicref/@type'
        end
      end
    end
  end

  def test_convert_map_mapref
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', []

    File.stub :read, 'topic contents' do
      cli.stub :parse_map, [[{ :target => 'file.adoc', :offset => 1 }]] do
        cli.stub :parse_topic, ['A map title', 'map'] do
          xml = cli.convert_map 'map contents', Pathname.new(Dir.pwd).expand_path

          assert_xpath_count xml, 1, '//mapref'
          assert_xpath_count xml, 0, '//topicref'
          assert_xpath_equal xml, 'file.ditamap', '/map/mapref/@href'
          assert_xpath_equal xml, 'ditamap', '/map/mapref/@format'
          assert_xpath_equal xml, 'map', '/map/mapref/@type'
        end
      end
    end
  end

  def test_convert_map_nesting
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', []
    incl = [
      { :target => 'file-1.adoc', :offset => 1 },
      { :target => 'file-2.adoc', :offset => 2 },
      { :target => 'file-3.adoc', :offset => 3 },
      { :target => 'file-4.adoc', :offset => 2 },
      { :target => 'file-5.adoc', :offset => 1 }
    ]

    File.stub :read, 'topic contents' do
      cli.stub :parse_map, [incl] do
        cli.stub :parse_topic, ['A topic title', 'concept'] do
          xml = cli.convert_map 'map contents', Pathname.new(Dir.pwd).expand_path

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
