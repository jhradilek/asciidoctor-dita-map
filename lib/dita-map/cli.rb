# Copyright (C) 2026 Jaromir Hradilek

# MIT License
#
# Permission  is hereby granted,  free of charge,  to any person  obtaining
# a copy of  this software  and associated documentation files  (the "Soft-
# ware"),  to deal in the Software  without restriction,  including without
# limitation the rights to use,  copy, modify, merge,  publish, distribute,
# sublicense, and/or sell copies of the Software,  and to permit persons to
# whom the Software is furnished to do so,  subject to the following condi-
# tions:
#
# The above copyright notice  and this permission notice  shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS",  WITHOUT WARRANTY OF ANY KIND,  EXPRESS
# OR IMPLIED,  INCLUDING BUT NOT LIMITED TO  THE WARRANTIES OF MERCHANTABI-
# LITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT
# SHALL THE AUTHORS OR COPYRIGHT HOLDERS  BE LIABLE FOR ANY CLAIM,  DAMAGES
# OR OTHER LIABILITY,  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM,  OUT OF OR IN CONNECTION WITH  THE SOFTWARE  OR  THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

require 'optparse'
require 'pathname'
require_relative 'convert'
require_relative 'version'

module AsciidoctorDitaMap
  class Cli
    def initialize argv
      @output    = nil
      @converter = Convert.new
      @args      = self.parse_args argv
    end

    def parse_args argv
      parser = OptionParser.new do |opt|
        opt.banner  = "Usage: #{NAME} [OPTION...] [FILE...]\n"
        opt.banner += "       #{NAME} -h|-v\n\n"

        opt.on('-o', '--out-file FILE', 'specify the output file; by default, the output file name is based on the input file') do |output|
          @output = (output.strip == '-') ? $stdout : output
        end

        opt.on('-a', '--attribute ATTRIBUTE', 'set a document attribute in the form of name, name!, or name=value pair; can be supplied multiple times') do |value|
          @converter.attr.append value
        end

        opt.separator ''

        opt.on('-p', '--prepend-file FILE', 'prepend a file to all input files; can be supplied multiple times') do |file|
          raise OptionParser::InvalidArgument, "not a file: #{file}" unless File.exist? file and File.file? file
          raise OptionParser::InvalidArgument, "file not readable: #{file}" unless File.readable? file

          @converter.prep << File.read(file)
          @converter.prep << "\n"
        end

        opt.on('-i', '--include-self', 'make the supplied file the toplevel topicref') do
          @converter.opts[:self] = true
        end

        opt.separator ''

        opt.on('-I', '--no-id', 'do not generate the map id attribute') do
          @converter.opts[:id] = false
        end

        opt.on('-M', '--no-maptitle', 'do not generate the map title') do
          @converter.opts[:title] = false
        end

        opt.on('-A', '--no-assembly', 'do treat assemblies as maps') do
          @converter.opts[:assembly] = false
        end

        opt.on('-C', '--no-chunk', 'do not generate the chunk attribute') do
          @converter.opts[:chunk] = false
        end

        opt.on('-L', '--no-locktitle', 'do not generate the locktitle attribute') do
          @converter.opts[:locktitle] = false
        end

        opt.on('-N', '--no-navtitle', 'do not generate the navtitle attribute') do
          @converter.opts[:navtitle] = false
        end

        opt.on('-O', '--no-toc', 'do not generate the toc attribute') do
          @converter.opts[:toc] = false
        end

        opt.on('-T', '--no-type', 'do not generate the type attribute') do
          @converter.opts[:type] = false
        end

        opt.separator ''

        opt.on('-v', '--verbose', 'report additional problems in the supplied files') do
          @converter.opts[:verbose] = true
        end

        opt.on('-z', '--zero-offset', 'allow include directives with zero leveloffset') do
          @converter.opts[:zero_offset] = true
        end

        opt.separator ''

        opt.on('-h', '--help', 'display this help and exit') do
          puts opt
          exit
        end

        opt.on('-V', '--version', 'display version information and exit') do
          puts "#{NAME} #{VERSION}"
          exit
        end
      end

      args = parser.parse argv

      if args.length == 0 or args[0].strip == '-'
        return [$stdin]
      end

      args.each do |file|
        raise OptionParser::InvalidArgument, "not a file: #{file}" unless File.exist? file and File.file? file
        raise OptionParser::InvalidArgument, "file not readable: #{file}" unless File.readable? file
      end

      return args
    end

    def run
      @args.each do |file|
        if file == $stdin
          base_dir = Pathname.new(Dir.pwd).expand_path
          input    = $stdin.read
          output   = @output ? @output : $stdout
        else
          base_dir = Pathname.new(file).dirname.expand_path
          input    = File.read(file)
          output   = @output ? @output : Pathname.new(file).sub_ext('.ditamap').to_s
        end

        if @converter.opts[:self] and file != $stdin
          result = @converter.run input, base_dir, file
        else
          result = @converter.run input, base_dir
        end

        if output == $stdout
          $stdout.write result
        else
          File.write output, result
        end
      end
    end
  end
end
