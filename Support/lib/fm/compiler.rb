#!/usr/bin/env ruby -wKU
# encoding: utf-8

module FlexMate

  class Compiler

    def initialize
      FlexMate::SDK.add_flex_bin_to_path
    end

    # Run mxmlc or compc to compile a swf adapting to the current environment as
    # necessary.
    #
    def build
      
      s = FlexMate::Settings.new
      
      cmd = build_tool(s)

      TextMate.require_cmd(cmd.name)
            
      init_html(cmd)
      
      exhaust = get_exhaust
      TextMate::Process.run(cmd.line) do |str|
        STDOUT << exhaust.line(str)
      end

      STDOUT << exhaust.complete
      
      STDOUT << '<br/><br/><div class="raw_out"><span class="showhide">'
      STDOUT << "<a href=\"javascript:hideElement('raw_out')\" id='raw_out_h' style='display: none;'>&#x25BC; Hide Raw Output</a>"
      STDOUT << "<a href=\"javascript:showElement('raw_out')\" id='raw_out_s' style=''>&#x25B6; Show Raw Output</a>"
      STDOUT << '</span></div>'
      STDOUT << '<div class="inner" id="raw_out_b" style="display: none;"><br/>'
      STDOUT << "<code>#{exhaust.input.to_s}</code><br/>"      
      
      html_footer

    end
    
    protected
    
    # Print initial html header.
    #
    def init_html(cmd)
      
      require ENV['TM_SUPPORT_PATH'] + '/lib/web_preview'
      puts html_head( :window_title => "ActionScript 3 Build Command",
                      :page_title => "Build (#{cmd.name})",
                      :sub_title => "#{cmd.file_specs_name}" )
      
      puts "<h2>Building...</h2>"
      puts "<p><pre>#{cmd.to_s}</pre></p>"
      
    end
    
    # Create the object responsible for parsing the compiler output.
    #
    def get_exhaust
      require 'fm/mxmlc_exhaust'
      MxmlcExhaust.new
    end
    
    # Create the command responsible for compiling the source.
    #
    def build_tool(settings)
        return CompcCommand.new(settings) if settings.is_swc
        return MxmlcCommand.new(settings)
    end

  end
  
  class FcshCompiler < Compiler
    def initialize
      super
    end
    
    # Run mxmlc inside the fcsh wrapper to compile.
    #
    def build
      
      bin = 'fcsh'
      
      TextMate.require_cmd(bin)
      
      s = FlexMate::Settings.new
      
      ENV['TM_FLEX_FILE_SPECS'] = s.file_specs
      ENV['TM_FLEX_OUTPUT'] = s.flex_output
      
      #WARN: Accessing s.flex_output after this point will fail. This is because 
      #      settings expects TM_FLEX_OUTPUT to be relative to the project root
      #      + we've just set it to a full path.
      
      FlexMate.required_settings({ :files => ['TM_FLEX_FILE_SPECS'],
                                   :evars => ['TM_FLEX_OUTPUT'] })
      
      cmd = build_tool(s)
      
      fcsh = e_sh(ENV['TM_FLEX_PATH'] + '/bin/fcsh')

      #Make sure there are no spaces for fcsh to trip up on.
      FlexMate.check_valid_paths([cmd.file_specs,cmd.o,fcsh])
      init_html(cmd)
      
      `osascript -e 'tell application "Terminal" to activate'` unless ENV['TM_FLEX_BACKGROUND_TERMINAL']
      `#{e_sh ENV['TM_BUNDLE_SUPPORT']}/lib/fcsh_terminal \"#{fcsh}\" \"#{cmd.line}\" >/dev/null;`
      
      html_footer
      
    end
    
  end

end

# Object to encapsulate a mxmlc command and its arguments.
#
class MxmlcCommand
  
  attr_reader :file_specs
  attr_reader :o
  attr_reader :name
  attr_reader :flex_options
  
  def initialize(settings)
    @name = 'mxmlc'
    @o = settings.flex_output
    @file_specs = settings.file_specs
    @flex_options = settings.flex_options
  end

  def line
    "#{name} -file-specs=#{e_sh file_specs} -o=#{e_sh o} #{flex_options}"
  end

  def file_specs_name
    File.basename(file_specs)
  end
  
  def to_s
    "-file-specs=#{file_specs}\n-o=#{e_sh o} #{flex_options}"
  end

end

# Object to encapsulate a compc command and its arguments.
#
class CompcCommand < MxmlcCommand
  
  attr_reader :include_classes
  attr_reader :source_path
  
  def initialize(settings)
    super(settings)
    @name = 'compc'
    @include_classes = settings.list_classes
    @source_path = settings.source_path
  end  
  
  def line
    "#{name} -source-path+=#{e_sh source_path} -o=#{e_sh o} #{include_classes}"
  end
  
  def to_s
    "#{name} -source-path+=#{e_sh source_path} -o=#{e_sh o}\n-include-classes=#{include_classes}"
  end

end

if __FILE__ == $0

  require ENV['TM_SUPPORT_PATH'] + '/lib/escape'
  require ENV['TM_SUPPORT_PATH'] + '/lib/exit_codes'
  require ENV['TM_SUPPORT_PATH'] + '/lib/textmate'
  require ENV['TM_SUPPORT_PATH'] + '/lib/tm/process'

  require '../add_lib'
  require 'fm/sdk'
  require 'fm/settings'
  require 'as3/source_tools'
  
  #There's no error checking at any point so we fall back on TM_CURRENT_FILE 
  #and mxmlc is perfectly happy to compile some ruby! If only :)
  FlexMate::Compiler.new.build
  
  #FlexMate::FcshCompiler.new.build

  FlexMate::Compiler.new.build

end
