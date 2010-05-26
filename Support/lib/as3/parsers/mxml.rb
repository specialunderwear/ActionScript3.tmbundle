#!/usr/bin/env ruby
# encoding: utf-8

################################################################################
#
#   Copyright 2009 Simon Gregory
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################

# A object representing the information on class members found within a
# mxml document.
#
# This is work in progress and parsing only looks at any xml in the document (script
# tags are ignored).
#
class MxmlDoc

  attr_accessor :super_class
  attr_accessor :super_namespace
  attr_accessor :namespaces
  attr_accessor :properties

  def initialize(doc)
    require 'rexml/document'
    @source = REXML::Document.new doc

    @super_class = @source.root.name
    @super_namespace = @source.root.namespace
    @properties = []
    
    parse_namespaces
    
    @script = ""

    add_members(@source.root)
  end

  def to_s
    s = []
    s << "super_class: #{super_class}\n"
    s << "super_namespace: #{@super_namespace}\n\n"
    s << "namespaces: #{@namespaces}\n\n"
    properties.each { |e| s << e.to_s + "\n\n" }
    s << "Script:\n#{@script}"
    s.to_s
  end
  
  def get_namespace_with_prefix(id)
    @namespaces.find { |ns| (ns[:prefix] == id) }
  end
  
  # Boolean indicating wether or not the document has a default namesapce 
  # specified.
  #
  def using_default_namespace
    return true if get_namespace_with_prefix('')
    false
  end
  
  def default_namespace_uri
    get_namespace_with_prefix('')[:name]
  end
  
  protected

  # Currently adds all properties found in the XML portion of the document. This
  # should be expanded to include methods, etc.
  #
  def add_members(node)

    if node.name() == 'Script'
      @script << "#{node.children.to_s}\n"
    elsif node.attributes['id']
      properties << MemberToken.new(node.attributes['id'], node.name,node.namespace)
    end

    node.elements.each { |child|
        add_members(child)
    }

  end
  
  # Lists all the namespaces defined in the root node of doc.
  #
  def parse_namespaces
    
    @namespaces = []
    
    @source.root.namespaces.each { |ns|
      pf = ( ns[0]  == 'xmlns' ) ? '' : ns[0]
      nm = ns[1]
      @namespaces << { :prefix => pf, :name => nm, }
    }
    
    #ns_regexp = /xmlns:?(\w+)?=([\'\"])([\w.*\/:]+)([\'\"])/
    #ns = []
    #doc.each { |line| 
    #  if line =~ ns_regexp
    #    ns << { :prefix => "#{$1}", :name => $2, }
    #    puts $1
    #  end
    #}
    
    # @namespaces = ns.uniq
    
  end
  
end

# Class member token.
#
class MemberToken

  attr_accessor :name
  attr_accessor :type
  attr_accessor :signature
  attr_accessor :ns

  def initialize(name,type,ns='',signature='')
    @name = name
    @type = type
    @signature = signature
    @ns = ns
  end

  def to_s
    "Name:#{name} Type:#{type} Namespace:#{ns}"
  end

end

if __FILE__ == $0
  
  TEST_DOC = '<?xml version="1.0" encoding="utf-8"?>
<vw:GTIApplication
    xmlns="http://www.adobe.com/2006/mxml"
    xmlns:vw="http://www.vw.co.uk/2009/vw/gti"
    xmlns:test="uk.co.vw.test.*">

    <Style source="/../resources/style/main.css" />

    <Script><![CDATA[import uk.co.vw.foo.Bar;]]></Script>
    <Script>import uk.co.vw.bar.Foo;</Script>

    <vw:SiteView id="siteView" />

    <vw:DialogContainer id="dialogContainer" />

    <Canvas id="underlay"/>

    <test:Box id="test" />

</vw:GTIApplication>'
  
  require "test/unit"
  
  class TestMxmlDoc < Test::Unit::TestCase

    def test_super_class
      mxp = MxmlDoc.new(TEST_DOC)
      assert_equal("GTIApplication", mxp.super_class)
    end
    
    def test_super_namespace
      mxp = MxmlDoc.new(TEST_DOC)
      assert_equal("http://www.vw.co.uk/2009/vw/gti", mxp.super_namespace)
    end
    
    def test_namespaces
      mxp = MxmlDoc.new(TEST_DOC)
      assert_equal(3, mxp.namespaces.length)
      assert_equal('http://www.vw.co.uk/2009/vw/gti', mxp.get_namespace_with_prefix('vw')[:name])
      assert_equal('http://www.adobe.com/2006/mxml', mxp.get_namespace_with_prefix('')[:name])
      assert_equal('http://www.adobe.com/2006/mxml', mxp.default_namespace_uri)
      assert_equal('uk.co.vw.test.*', mxp.get_namespace_with_prefix('test')[:name])
      assert_equal(true,mxp.using_default_namespace)
    end
    
    def test_properties
      mxp = MxmlDoc.new(TEST_DOC)
      assert_equal(4, mxp.properties.length)
      
      tok = find_item(mxp.properties, 'underlay')
      assert_equal('underlay', tok.name)
      assert_equal('Canvas', tok.type)
      assert_equal('http://www.adobe.com/2006/mxml', tok.ns)

      tok = find_item(mxp.properties, 'siteView')      
      assert_equal('siteView', tok.name)
      assert_equal('SiteView', tok.type)
      assert_equal('http://www.vw.co.uk/2009/vw/gti', tok.ns)
      
      tok = find_item(mxp.properties, 'dialogContainer')      
      assert_equal('dialogContainer', tok.name)
      assert_equal('DialogContainer', tok.type)
      assert_equal('http://www.vw.co.uk/2009/vw/gti', tok.ns)
      
      tok = find_item(mxp.properties, 'test')      
      assert_equal('test', tok.name)
      assert_equal('Box', tok.type)
      assert_equal('uk.co.vw.test.*', tok.ns)

    end
    
    def find_item(a,id)
      t = a.select {|o| o.name == id }
      t[0]
    end
    
  end

end