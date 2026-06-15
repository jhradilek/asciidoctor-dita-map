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

module AsciidoctorDitaMap
  class Topic
    attr_accessor :title, :type

    def initialize input, attributes = []
      if input.empty?
        @title = nil
        @type  = nil
      else
        doc = Asciidoctor.load input, safe: :secure, attributes: attributes

        @title = doc.title ? doc.title.gsub(/<[^>]*>/, '') : nil
        @type  = get_content_type doc.attributes
      end
    end

    private

    def get_content_type attributes
      type = attributes['_mod-docs-content-type'] ? attributes['_mod-docs-content-type'].downcase : nil
      type = attributes['_content-type'] ? attributes['_content-type'].downcase : nil unless type
      type = attributes['_module-type'] ? attributes['_module-type'].downcase : nil unless type

      if type
        type.sub!(/^procedure$/, 'task')
      end

      unless ['assembly', 'concept', 'reference', 'task', 'map', 'attributes', 'snippet'].include? type
        return nil
      end

      return type
    end
  end
end
