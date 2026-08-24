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

require 'asciidoctor'
require_relative 'catalog'
require_relative 'topic'

module AsciidoctorDitaMap
  class Map < Topic
    attr_accessor :chunk, :id, :includes, :navtitle

    def initialize input, base_dir, attributes = []
      if input.empty?
        @id       = nil
        @title    = nil
        @navtitle = nil
        @type     = nil
        @includes = []
        @chunk    = false
      else
        Asciidoctor::Extensions.register do
          include_processor CatalogIncludeDirectives
        end

        doc = Asciidoctor.load input, safe: :safe, logger: false, catalog_assets: true, attributes: attributes, base_dir: base_dir

        @includes = doc.catalog[:include_files] ? doc.catalog[:include_files] : []
        @id       = doc.id ? doc.id.gsub(/["']/, '') : nil
        @title    = doc.title ? doc.title.gsub(/<[^>]*>/, '') : nil
        @navtitle = (doc.attributes.key? 'navtitle') ? doc.attributes['navtitle'] : nil
        @type     = get_content_type doc.attributes
        @chunk    = doc.attributes.key? 'chunk-to-content'
      end
    end
  end
end
