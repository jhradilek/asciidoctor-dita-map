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

require 'rexml/document'
require_relative 'topic'
require_relative 'map'

module AsciidoctorDitaMap
  class Convert
    attr_accessor :attr, :opts, :prep

    def initialize
      @attr = []
      @opts = {
        :chunk => true,
        :id => true,
        :locktitle => true,
        :navtitle => true,
        :title => true,
        :toc => true,
        :type => true,
        :self => false,
        :verbose => false,
        :zero_offset => false
      }
      @prep = ''
    end

    def compose_mapref_attributes file_info, type
      target_file         = file_info[:target].sub(/\.adoc$/, '.ditamap')
      attributes          = { 'href' => target_file, 'format' => 'ditamap' }
      attributes['type']  = type if @opts[:type]
      attributes['chunk'] = file_info[:chunk] if @opts[:chunk] and file_info[:chunk]
      attributes['toc']   = file_info[:toc] if @opts[:toc] and file_info[:toc]

      return attributes
    end

    def compose_topicref_attributes file_info, title, type
      target_file             = file_info[:target].sub(/\.adoc$/, '.dita')
      attributes              = { 'href' => target_file }
      attributes['navtitle']  = title if @opts[:navtitle] and title
      attributes['locktitle'] = 'yes' if @opts[:locktitle] and attributes['navtitle']
      attributes['type']      = type if @opts[:type] and type and ['concept', 'reference', 'task'].include? type
      attributes['chunk']     = file_info[:chunk] if @opts[:chunk] and file_info[:chunk]
      attributes['toc']       = file_info[:toc] if @opts[:toc] and file_info[:toc]

      return attributes
    end

    def run input, base_dir, file = nil
      result = ''

      map = Map.new @prep + input, base_dir, @attr

      xml = REXML::Document.new
      xml.context[:attribute_quote] = :quote
      xml << REXML::XMLDecl.new('1.0', 'utf-8')
      xml << REXML::DocType.new('map', 'PUBLIC "-//OASIS//DTD DITA Map//EN" "map.dtd"')

      if map.id and @opts[:id]
        xml_root  = xml.add_element('map', { 'id' => map.id })
      else
        xml_root  = xml.add_element('map')
      end

      if map.title and @opts[:title]
        xml_title      = xml_root.add_element('title')
        xml_title.text = map.title
      end

      if @opts[:self] and file
        attributes = compose_topicref_attributes({ :target => file }, map.title, map.type)
        xml_self   = xml_root.add_element('topicref', attributes)
        stack      = [{ :offset => 0, :element => xml_self }]
      else
        stack      = [{ :offset => 0, :element => xml_root }]
      end

      map.includes.each do |file_info|
        target      = file_info[:target]
        offset      = file_info[:offset]
        last_offset = stack.last[:offset]
        full_path   = base_dir + target

        if not File.exist? full_path and @opts[:verbose]
          warn "#{NAME}: warning: file not found: #{target}"
        end

        begin
          topic = Topic.new @prep + File.read(full_path), @attr
          next if ['attributes', 'snippet'].include? topic.type
        rescue
          warn "#{NAME}: warning: unable to read included file: #{target}"
          topic = Topic.new ''
        end

        if offset == 0
          if @opts[:zero_offset]
            offset = 0
          else
            warn "#{NAME}: warning: invalid leveloffset - expected 1, got 0: #{target}"
            offset = 1
          end
        elsif offset > last_offset and offset - last_offset > 1
          expected_offset = last_offset + 1
          warn "#{NAME}: warning: invalid leveloffset - expected #{expected_offset}, got #{offset}: #{target}"
        end

        while stack.length > 1 and stack.last[:offset] >= offset
          stack.pop
        end

        xml_parent = stack.last[:element]

        if topic.type == 'map'
          attributes  = compose_mapref_attributes file_info, topic.type
          xml_element = xml_parent.add_element('mapref', attributes)
        else
          attributes  = compose_topicref_attributes file_info, topic.title, topic.type
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
  end
end
