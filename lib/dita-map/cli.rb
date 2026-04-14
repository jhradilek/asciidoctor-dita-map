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
require_relative 'version'

module AsciidoctorDitaMap
  class Cli
    def initialize name, argv
      @attr = []
      @opts = {
        :output => false,
        :standalone => true
      }
      @prep = []
      @name = name
      @args = self.parse_args argv
    end

    def parse_args argv
      parser = OptionParser.new do |opt|
        opt.banner  = "Usage: #{@name} [OPTION...] [FILE...]\n"
        opt.banner += "       #{@name} -h|-v\n\n"

        opt.on('-o', '--out-file FILE', 'specify the output file; by default, the output file name is based on the input file') do |output|
          @opts[:output] = (output.strip == '-') ? $stdout : output
        end

        opt.on('-a', '--attribute ATTRIBUTE', 'set a document attribute in the form of name, name!, or name=value pair; can be supplied multiple times') do |value|
          @attr.append value
        end

        opt.on('-s', '--no-header-footer', 'disable enclosing the content in <topic> and generating <title>') do
          @opts[:standalone] = false
        end

        opt.separator ''

        opt.on('-p', '--prepend-file FILE', 'prepend a file to all input files; can be supplied multiple times') do |file|
          raise OptionParser::InvalidArgument, "not a file: #{file}" unless File.exist? file and File.file? file
          raise OptionParser::InvalidArgument, "file not readable: #{file}" unless File.readable? file

          @prep.append file
        end

        opt.separator ''

        opt.on('-h', '--help', 'display this help and exit') do
          puts opt
          exit
        end

        opt.on('-v', '--version', 'display version information and exit') do
          puts "#{@name} #{VERSION}"
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
      puts "To be implemented..."
    end
  end
end
