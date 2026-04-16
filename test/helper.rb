require 'rexml/document'
require 'minitest'

# Remove this once the rexml deprecation warning is resolved upstream:
Warning[:deprecated] = false

class Minitest::Test
  def assert_xpath_count xml, exp, xpath, msg=nil
    assert_equal exp, REXML::XPath.match((REXML::Document.new xml), xpath).length, msg
  end

  def assert_xpath_equal xml, exp, xpath, msg=nil
    assert_equal exp, REXML::XPath.first((REXML::Document.new xml), xpath).to_s.strip, msg
  end

  def assert_xpath_includes xml, obj, xpath, msg=nil
    assert_includes REXML::XPath.match((REXML::Document.new xml), xpath).map { |s| s.to_s.strip }, obj, msg
  end
end
