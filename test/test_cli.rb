require 'minitest/autorun'
require 'minitest/mock'
require_relative '../lib/dita-map/cli'

class CliTest < Minitest::Test
  def test_defaults
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', []
    attr = cli.instance_variable_get :@attr
    opts = cli.instance_variable_get :@opts
    prep = cli.instance_variable_get :@prep

    assert_equal false, opts[:output]
    assert_equal true, opts[:standalone]
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

  def test_no_header_footer_short
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['-s']
    opts = cli.instance_variable_get :@opts

    assert_equal false, opts[:standalone]
  end

  def test_no_header_footer_long
    cli  = AsciidoctorDitaMap::Cli.new 'script-name', ['--no-header-footer']
    opts = cli.instance_variable_get :@opts

    assert_equal false, opts[:standalone]
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
    file = 'attributes.adoc'

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
end
