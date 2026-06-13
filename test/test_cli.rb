require 'minitest/autorun'
require 'minitest/mock'
require 'ostruct'
require 'pathname'
require_relative 'helper'
require_relative '../lib/dita-map/cli'

class CliTest < Minitest::Test
  def test_missing_file
    file = 'file.adoc'

    File.stub :exist?, false do
      File.stub :file?, true do
        error = assert_raises OptionParser::InvalidArgument do
          AsciidoctorDitaMap::Cli.new [file]
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
          AsciidoctorDitaMap::Cli.new [file]
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
            AsciidoctorDitaMap::Cli.new [file]
          end

          assert_match(/file not readable: #{file}/, error.message)
        end
      end
    end
  end

  def test_out_file_short
    cli  = AsciidoctorDitaMap::Cli.new ['-o', 'file.dita']
    out  = cli.instance_variable_get :@output

    assert_equal 'file.dita', out
  end

  def test_out_file_long
    cli  = AsciidoctorDitaMap::Cli.new ['--out-file', 'file.dita']
    out  = cli.instance_variable_get :@output

    assert_equal 'file.dita', out
  end

  def test_out_file_stdout
    cli  = AsciidoctorDitaMap::Cli.new ['-o', '-']
    out  = cli.instance_variable_get :@output

    assert_equal $stdout, out
  end

  def test_attribute_short
    cli  = AsciidoctorDitaMap::Cli.new ['-a', 'version=3']
    conv = cli.instance_variable_get :@converter

    assert_includes conv.attr, 'version=3'
  end

  def test_attribute_long
    cli  = AsciidoctorDitaMap::Cli.new ['--attribute', 'version=3']
    conv = cli.instance_variable_get :@converter

    assert_includes conv.attr, 'version=3'
  end

  def test_attribute_multiple
    cli  = AsciidoctorDitaMap::Cli.new ['-a', 'version=3', '-a', 'release=1']
    conv = cli.instance_variable_get :@converter

    assert_includes conv.attr, 'version=3'
    assert_includes conv.attr, 'release=1'
  end

  def test_prepend_file_short
    prep = 'prepended text'

    File.stub :exist?, true do
      File.stub :file?, true do
        File.stub :readable?, true do
          File.stub :read, prep do
            cli  = AsciidoctorDitaMap::Cli.new ['-p', 'attributes.adoc']
            conv = cli.instance_variable_get :@converter

            assert_equal conv.prep, "#{prep}\n"
          end
        end
      end
    end
  end

  def test_prepend_file_long
    prep = 'prepended text'

    File.stub :exist?, true do
      File.stub :file?, true do
        File.stub :readable?, true do
          File.stub :read, prep do
            cli  = AsciidoctorDitaMap::Cli.new ['--prepend-file', 'attributes.adoc']
            conv = cli.instance_variable_get :@converter

            assert_equal conv.prep, "#{prep}\n"
          end
        end
      end
    end
  end

  def test_prepend_file_multiple
    prep = 'prepended text'

    File.stub :exist?, true do
      File.stub :file?, true do
        File.stub :readable?, true do
          File.stub :read, prep do
            cli  = AsciidoctorDitaMap::Cli.new ['-p', 'first.adoc', '-p', 'second.adoc']
            conv = cli.instance_variable_get :@converter

            assert_equal conv.prep, "#{prep}\n"*2
          end
        end
      end
    end
  end

  def test_prepend_file_missing_file
    file = 'attributes.adoc'

    File.stub :exist?, false do
      File.stub :file?, true do
        error = assert_raises OptionParser::InvalidArgument do
          AsciidoctorDitaMap::Cli.new ['-p', file]
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
          AsciidoctorDitaMap::Cli.new ['-p', file]
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
            AsciidoctorDitaMap::Cli.new ['-p', file]
          end

          assert_match(/file not readable: #{file}/, error.message)
        end
      end
    end
  end

  def test_include_self_short
    cli  = AsciidoctorDitaMap::Cli.new ['-i']
    conv = cli.instance_variable_get :@converter

    assert_equal true, conv.opts[:self]
  end

  def test_include_self_long
    cli  = AsciidoctorDitaMap::Cli.new ['--include-self']
    conv = cli.instance_variable_get :@converter

    assert_equal true, conv.opts[:self]
  end

  def test_include_self_output
    cli  = AsciidoctorDitaMap::Cli.new ['--include-self']
    conv = cli.instance_variable_get :@converter
    mock = OpenStruct.new(:title => 'A topic title', :type => 'concept', :id => nil, :includes => [])

    AsciidoctorDitaMap::Map.stub :new, mock do
      xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path, 'file.adoc'

      assert_xpath_count xml, 1, '/map/topicref'
      assert_xpath_equal xml, 'file.dita', '/map/topicref/@href'
      assert_xpath_equal xml, 'A topic title', '/map/topicref/@navtitle'
      assert_xpath_equal xml, 'concept', '/map/topicref/@type'
    end
  end

  def test_no_id_short
    cli  = AsciidoctorDitaMap::Cli.new ['-I']
    conv = cli.instance_variable_get :@converter

    assert_equal false, conv.opts[:id]
  end

  def test_no_id_long
    cli  = AsciidoctorDitaMap::Cli.new ['--no-id']
    conv = cli.instance_variable_get :@converter

    assert_equal false, conv.opts[:id]
  end

  def test_no_id_output
    cli  = AsciidoctorDitaMap::Cli.new ['--no-id']
    conv = cli.instance_variable_get :@converter
    mock = OpenStruct.new(:title => nil, :type => nil, :id => 'map-id', :includes => [])

    AsciidoctorDitaMap::Map.stub :new, mock do
      xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

      assert_xpath_count xml, 0, '/map/@id'
    end
  end

  def test_no_maptitle_short
    cli  = AsciidoctorDitaMap::Cli.new ['-M']
    conv = cli.instance_variable_get :@converter

    assert_equal false, conv.opts[:title]
  end

  def test_no_maptitle_long
    cli  = AsciidoctorDitaMap::Cli.new ['--no-maptitle']
    conv = cli.instance_variable_get :@converter

    assert_equal false, conv.opts[:title]
  end

  def test_no_maptitle_output
    cli  = AsciidoctorDitaMap::Cli.new ['--no-maptitle']
    conv = cli.instance_variable_get :@converter
    mock = OpenStruct.new(:title => 'A map title', :type => nil, :id => nil, :includes => [])

    AsciidoctorDitaMap::Map.stub :new, mock do
      xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

      assert_xpath_count xml, 0, '/map/title'
    end
  end

  def test_no_chunk_short
    cli  = AsciidoctorDitaMap::Cli.new ['-C']
    conv = cli.instance_variable_get :@converter

    assert_equal false, conv.opts[:chunk]
  end

  def test_no_chunk_long
    cli  = AsciidoctorDitaMap::Cli.new ['--no-chunk']
    conv = cli.instance_variable_get :@converter

    assert_equal false, conv.opts[:chunk]
  end

  def test_no_chunk_output
    cli  = AsciidoctorDitaMap::Cli.new ['--no-chunk']
    conv = cli.instance_variable_get :@converter
    incl = [
      { :target => 'file.adoc', :offset => 1, :chunk => 'to-content' }
    ]
    mock_map   = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => incl)
    mock_topic = OpenStruct.new(:title => 'A topic title', :type => 'concept')

    File.stub :read, 'topic contents' do
      AsciidoctorDitaMap::Map.stub :new, mock_map do
        AsciidoctorDitaMap::Topic.stub :new, mock_topic do
          xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

          assert_xpath_count xml, 0, '//topicref/@chunk'
        end
      end
    end
  end

  def test_no_locktitle_short
    cli  = AsciidoctorDitaMap::Cli.new ['-L']
    conv = cli.instance_variable_get :@converter

    assert_equal false, conv.opts[:locktitle]
  end

  def test_no_locktitle_long
    cli  = AsciidoctorDitaMap::Cli.new ['--no-locktitle']
    conv = cli.instance_variable_get :@converter

    assert_equal false, conv.opts[:locktitle]
  end

  def test_no_locktitle_output
    cli  = AsciidoctorDitaMap::Cli.new ['--no-locktitle']
    conv = cli.instance_variable_get :@converter
    incl = [
      { :target => 'file.adoc', :offset => 1 }
    ]
    mock_map   = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => incl)
    mock_topic = OpenStruct.new(:title => 'A topic title', :type => 'concept')

    File.stub :read, 'topic contents' do
      AsciidoctorDitaMap::Map.stub :new, mock_map do
        AsciidoctorDitaMap::Topic.stub :new, mock_topic do
          xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

          assert_xpath_count xml, 1, '//topicref/@navtitle'
          assert_xpath_count xml, 0, '//topicref/@locktitle'
        end
      end
    end
  end

  def test_no_navtitle_short
    cli  = AsciidoctorDitaMap::Cli.new ['-N']
    conv = cli.instance_variable_get :@converter

    assert_equal false, conv.opts[:navtitle]
  end

  def test_no_navtitle_long
    cli  = AsciidoctorDitaMap::Cli.new ['--no-navtitle']
    conv = cli.instance_variable_get :@converter

    assert_equal false, conv.opts[:navtitle]
  end

  def test_no_navtitle_output
    cli  = AsciidoctorDitaMap::Cli.new ['--no-navtitle']
    conv = cli.instance_variable_get :@converter
    incl = [
      { :target => 'file.adoc', :offset => 1 }
    ]
    mock_map   = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => incl)
    mock_topic = OpenStruct.new(:title => 'A topic title', :type => 'concept')

    File.stub :read, 'topic contents' do
      AsciidoctorDitaMap::Map.stub :new, mock_map do
        AsciidoctorDitaMap::Topic.stub :new, mock_topic do
          xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

          assert_xpath_count xml, 0, '//topicref/@navtitle'
        end
      end
    end
  end

  def test_no_toc_short
    cli  = AsciidoctorDitaMap::Cli.new ['-O']
    conv = cli.instance_variable_get :@converter

    assert_equal false, conv.opts[:toc]
  end

  def test_no_toc_long
    cli  = AsciidoctorDitaMap::Cli.new ['--no-toc']
    conv = cli.instance_variable_get :@converter

    assert_equal false, conv.opts[:toc]
  end

  def test_no_toc_output
    cli  = AsciidoctorDitaMap::Cli.new ['--no-toc']
    conv = cli.instance_variable_get :@converter
    incl = [
      { :target => 'file.adoc', :offset => 1, :toc => 'no' }
    ]
    mock_map   = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => incl)
    mock_topic = OpenStruct.new(:title => 'A topic title', :type => 'concept')

    File.stub :read, 'topic contents' do
      AsciidoctorDitaMap::Map.stub :new, mock_map do
        AsciidoctorDitaMap::Topic.stub :new, mock_topic do
          xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

          assert_xpath_count xml, 0, '//topicref/@toc'
        end
      end
    end
  end

  def test_no_type_short
    cli  = AsciidoctorDitaMap::Cli.new ['-T']
    conv = cli.instance_variable_get :@converter

    assert_equal false, conv.opts[:type]
  end

  def test_no_type_long
    cli  = AsciidoctorDitaMap::Cli.new ['--no-type']
    conv = cli.instance_variable_get :@converter

    assert_equal false, conv.opts[:type]
  end

  def test_no_type_output
    cli  = AsciidoctorDitaMap::Cli.new ['--no-type']
    conv = cli.instance_variable_get :@converter
    incl = [
      { :target => 'file.adoc', :offset => 1 }
    ]
    mock_map   = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => incl)
    mock_topic = OpenStruct.new(:title => 'A topic title', :type => 'concept')

    File.stub :read, 'topic contents' do
      AsciidoctorDitaMap::Map.stub :new, mock_map do
        AsciidoctorDitaMap::Topic.stub :new, mock_topic do
          xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

          assert_xpath_count xml, 0, '//topicref/@type'
        end
      end
    end
  end

  def test_verbose_short
    cli  = AsciidoctorDitaMap::Cli.new ['-v']
    conv = cli.instance_variable_get :@converter

    assert_equal true, conv.opts[:verbose]
  end

  def test_verbose_long
    cli  = AsciidoctorDitaMap::Cli.new ['--verbose']
    conv = cli.instance_variable_get :@converter

    assert_equal true, conv.opts[:verbose]
  end

  def test_verbose_warning
    cli  = AsciidoctorDitaMap::Cli.new ['--verbose']
    conv = cli.instance_variable_get :@converter
    file = 'file.adoc'
    incl = [
      { :target => file, :offset => 1 }
    ]
    mock = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => incl)

    AsciidoctorDitaMap::Map.stub :new, mock do
      File.stub :exist?, false do
        assert_output(nil, /file not found: #{file}/) do
          conv.run 'map contents', Pathname.new(Dir.pwd).expand_path
        end
      end
    end
  end

  def test_zero_offset_short
    cli  = AsciidoctorDitaMap::Cli.new ['-z']
    conv = cli.instance_variable_get :@converter

    assert_equal true, conv.opts[:zero_offset]
  end

  def test_zero_offset_long
    cli  = AsciidoctorDitaMap::Cli.new ['--zero-offset']
    conv = cli.instance_variable_get :@converter

    assert_equal true, conv.opts[:zero_offset]
  end

  def test_zero_offset_no_warning
    cli  = AsciidoctorDitaMap::Cli.new ['--zero-offset']
    conv = cli.instance_variable_get :@converter
    incl = [
      { :target => 'file-1.adoc', :offset => 0 },
      { :target => 'file-2.adoc', :offset => 1 },
      { :target => 'file-3.adoc', :offset => 0 }
    ]
    mock_map   = OpenStruct.new(:title => nil, :type => nil, :id => nil, :includes => incl)
    mock_topic = OpenStruct.new(:title => 'A topic title', :type => 'concept')

    File.stub :read, 'topic contents' do
      AsciidoctorDitaMap::Map.stub :new, mock_map do
        AsciidoctorDitaMap::Topic.stub :new, mock_topic do
          assert_output(nil, '') do
            xml = conv.run 'map contents', Pathname.new(Dir.pwd).expand_path

            assert_xpath_equal xml, 'file-1.dita', '/map/topicref[1]/@href'
            assert_xpath_equal xml, 'file-2.dita', '/map/topicref[1]/topicref/@href'
            assert_xpath_equal xml, 'file-3.dita', '/map/topicref[2]/@href'
          end
        end
      end
    end
  end

  def test_help_short
    assert_output(/^Usage: #{AsciidoctorDitaMap::NAME} /) do
      error = assert_raises SystemExit do
        AsciidoctorDitaMap::Cli.new ['-h']
      end

      assert_equal 0, error.status
    end
  end

  def test_help_long
    assert_output(/^Usage: #{AsciidoctorDitaMap::NAME} /) do
      error = assert_raises SystemExit do
        AsciidoctorDitaMap::Cli.new ['--help']
      end

      assert_equal 0, error.status
    end
  end

  def test_version_short
    assert_output(/^#{AsciidoctorDitaMap::NAME} #{AsciidoctorDitaMap::VERSION}$/) do
      error = assert_raises SystemExit do
        AsciidoctorDitaMap::Cli.new ['-V']
      end

      assert_equal 0, error.status
    end
  end

  def test_version_long
    assert_output(/^#{AsciidoctorDitaMap::NAME} #{AsciidoctorDitaMap::VERSION}$/) do
      error = assert_raises SystemExit do
        AsciidoctorDitaMap::Cli.new ['--version']
      end

      assert_equal 0, error.status
    end
  end
end
