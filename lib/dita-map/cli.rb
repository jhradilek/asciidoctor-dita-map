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
require 'asciidoctor'
require 'rexml/document'
require_relative 'catalog'
require_relative 'version'

module AsciidoctorDitaMap
  class Cli
    def initialize name, argv
      @attr = []
      @opts = {
        :id => true,
        :navtitle => true,
        :output => false,
        :title => true,
        :type => true
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

        opt.separator ''

        opt.on('-p', '--prepend-file FILE', 'prepend a file to all input files; can be supplied multiple times') do |file|
          raise OptionParser::InvalidArgument, "not a file: #{file}" unless File.exist? file and File.file? file
          raise OptionParser::InvalidArgument, "file not readable: #{file}" unless File.readable? file

          @prep.append file
        end

        opt.separator ''

        opt.on('-I', '--no-id', 'do not generate the map id attribute') do
          @opts[:id] = false
        end

        opt.on('-M', '--no-maptitle', 'do not generate the map title') do
          @opts[:title] = false
        end

        opt.on('-N', '--no-navtitle', 'do not generate the navtitle attribute') do
          @opts[:navtitle] = false
        end

        opt.on('-T', '--no-type', 'do not generate the type attribute') do
          @opts[:type] = false
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

    def parse_topic input
      doc = Asciidoctor.load input, safe: :secure, attributes: @attr
      att = doc.attributes

      document_title = doc.title ? doc.title.gsub(/<[^>]*>/, '') : nil
      document_type  = att['_mod-docs-content-type'] ? att['_mod-docs-content-type'].downcase : nil
      document_type  = att['_content-type'] ? att['_content-type'].downcase : nil unless document_type
      document_type  = att['_module-type'] ? att['_module-type'].downcase : nil unless document_type

      if document_type
        document_type.sub!(/^assembly$/, 'concept')
        document_type.sub!(/^procedure$/, 'task')
      end

      unless ['concept', 'reference', 'task', 'map'].include? document_type
        document_type = nil
      end

      return document_title, document_type
    end


    def parse_map input, base_dir
      Asciidoctor::Extensions.register do
        include_processor CatalogIncludeDirectives
      end

      doc = Asciidoctor.load input, safe: :safe, catalog_assets: true, attributes: @attr, base_dir: base_dir

      include_files  = doc.catalog[:include_files] ? doc.catalog[:include_files] : []
      document_title = doc.title ? doc.title.gsub(/<[^>]*>/, '') : nil
      document_id    = doc.id ? doc.id.gsub(/["']/, '') : nil

      return include_files, document_title, document_id
    end

    def convert_map input, base_dir, prepended = ''
      result = ''

      include_files, map_title, document_id = parse_map prepended + input, base_dir

      xml = REXML::Document.new
      xml.context[:attribute_quote] = :quote
      xml << REXML::XMLDecl.new('1.0', 'utf-8')
      xml << REXML::DocType.new('map', 'PUBLIC "-//OASIS//DTD DITA Map//EN" "map.dtd"')

      if document_id and @opts[:id]
        xml_root  = xml.add_element('map', { 'id' => document_id })
      else
        xml_root  = xml.add_element('map')
      end

      if map_title and @opts[:title]
        xml_title = xml_root.add_element('title')
        xml_title.text = map_title
      end

      stack = [{ :offset => 0, :element => xml_root }]

      include_files.each do |file|
        target      = file[:target]
        offset      = file[:offset]
        last_offset = stack.last[:offset]

        if offset == 0
          warn "#{@name}: warning: Invalid leveloffset - expected 1, got 0: #{target}"
          offset = 1
        elsif offset > last_offset and offset - last_offset > 1
          expected_offset = last_offset + 1
          warn "#{@name}: warning: Invalid leveloffset - expected #{expected_offset}, got #{offset}: #{target}"
          offset = expected_offset
        end

        while stack.last[:offset] >= offset
          stack.pop
        end

        xml_parent   = stack.last[:element]

        if @opts[:navtitle] or @opts[:type]
          begin
            include_title, include_type = parse_topic prepended + File.read(base_dir + target)
          rescue
            warn "#{@name}: warning: Unable to read included file: #{base_dir + target}"
            include_title, include_type = nil, nil
          end
        end

        if include_type == 'map'
          file_name          = target.sub(/\.adoc$/, '.ditamap')
          attributes         = { 'href' => file_name, 'format' => 'ditamap' }
          attributes['type'] = include_type if @opts[:type]

          xml_element = xml_parent.add_element('mapref', attributes)
        else
          file_name = target.sub(/\.adoc$/, '.dita')
          attributes             = { 'href' => file_name }
          attributes['navtitle'] = include_title if include_title and @opts[:navtitle]
          attributes['type']     = include_type if include_type and @opts[:type]

          xml_element = xml_parent.add_element('topicref', attributes)
        end

        stack.push ({ :offset => offset, :element => xml_element })
      end

      formatter = REXML::Formatters::Pretty.new(2, true)
      formatter.compact = true
      formatter.write(xml, result)

      result << "\n"

      return result
    end

    def run
      prepended = ''

      @prep.each do |file|
        prepended << File.read(file)
        prepended << "\n"
      end

      @args.each do |file|
        if file == $stdin
          base_dir = Pathname.new(Dir.pwd).expand_path
          input    = $stdin.read
          output   = @opts[:output] ? @opts[:output] : $stdout
        else
          base_dir = Pathname.new(file).dirname.expand_path
          input    = File.read(file)
          output   = @opts[:output] ? @opts[:output] : Pathname.new(file).sub_ext('.ditamap').to_s
        end

        result = convert_map input, base_dir, prepended

        if output == $stdout
          $stdout.write result
        else
          File.write output, result
        end
      end
    end
  end
end
