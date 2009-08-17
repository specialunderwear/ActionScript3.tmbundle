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

# Utility class for working with ActionScript manifest files.
#
class Manifest

  def initialize(doc)
    @doc = strip_comments(doc)
  end
  
  def find_class(id)
    
    rgx = /<component\s+id=["'](#{id})["']\s+class=["']([\w.]+)["']/
    res = []
    res = @doc.scan(rgx)

    return nil if res.empty?
    
    res[0][1]
    
  end
    
  def classes

    rgx = /<component\s+id=["'](\w+)["']\s+class=["']([\w.]+)["']/
    cls = []
    @doc.each { |line|  cls << $1 if line =~ rgx }
    cls
    
  end
  
  protected
  
  # Strips comments from the document.
	#
	def strip_comments(doc)

		multiline_comments = /<!--(?:.|([\r\n]))*?-->/
		doc.gsub!(multiline_comments,'')
		
		single_line_comments = /<!--.*-->/
		return doc.gsub(single_line_comments,'')

	end
  
end

if __FILE__ == $0
  
  TEST_MANIFEST = '<?xml version="1.0"?>
<componentPackage>
  <component id="ApplicationMediator" class="org.helvector.game.view.mediators.ApplicationMediator" />
  <component id="ApplicationProxy" class=\'org.helvector.game.model.proxies.ApplicationProxy\' />
  <!-- <component id="HowToPlayDialogMediator" class="org.helvector.game.view.mediators.dialogs.HowToPlayDialogMediator" /> -->
  <component id=\'InitialLoadProportions\' class="org.helvector.game.io.InitialLoadProportions" />
  <component id="LapTimes" class="org.helvector.game.view.controls.game.LapTimes" />
  <!--
  <component id="LeaderBoardEntryVO" class="org.helvector.game.model.domain.local.LeaderBoardEntryVO" />
  -->
  <component id="RaceData" 
             class="org.helvector.game.constants.RaceData" />
  <component id="RaceVO" class="org.helvector.game.model.domain.local.RaceVO" />
  <component id="RemoteServices" class="org.helvector.game.io.RemoteServices" />
  <component id="TrackingCallCommand" class="org.helvector.game.controller.TrackingCallCommand" />
  <component id="UserProxy" class="org.helvector.game.model.proxies.domain.UserProxy" />
</componentPackage>'
  
   require "test/unit"

   class TestMxmlDoc < Test::Unit::TestCase

     def test_find_class
       
       m = Manifest.new(TEST_MANIFEST)

       found = m.find_class('RaceData')       
       assert_equal('org.helvector.game.constants.RaceData',found)
       
       found = m.find_class('DummyClass')
       assert_equal(nil,found)

       found = m.find_class('ApplicationProxy')
       assert_equal('org.helvector.game.model.proxies.ApplicationProxy',found)
       
     end
     
     def test_classes
      
      m = Manifest.new(TEST_MANIFEST)
      c = m.classes
      
      assert_equal('ApplicationMediator', c[0])
      assert_equal('ApplicationProxy', c[1])
      assert_equal('InitialLoadProportions', c[2])
      assert_equal('LapTimes', c[3])
      assert_equal('RaceData', c[4])
      
     end
   end
end
