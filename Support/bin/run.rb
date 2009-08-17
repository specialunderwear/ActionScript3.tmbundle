#!/usr/bin/env ruby
# encoding: utf-8

SUPPORT = ENV['TM_SUPPORT_PATH']

require SUPPORT + '/lib/escape'
require SUPPORT + '/lib/web_preview'
require SUPPORT + '/lib/tm/process'

proj = ENV['TM_PROJECT_DIRECTORY']
run_file = ENV['TM_FLEX_RUN_FILE'] || 'build/launch.sh'
flex_out = ENV['TM_FLEX_OUTPUT']

proj_run_file = proj ? "#{proj}/#{run_file}" : ""
proj_default  = proj ? "#{proj}/deploy/index.html" : ""
proj_flex_out = proj ? "#{proj}/#{flex_out}" : ""

def run(uri)
  
  if File.executable?(uri)
    puts "<h2>Executing</h2><pre>#{File.basename(uri)}</pre>"
    cmd = e_sh(uri)
  else
    puts "<h2>Opening...</h2><pre>#{File.basename(uri)}</pre>"
    cmd = "open #{e_sh(uri)}"
  end
  
  TextMate::Process.run(cmd) do |str|
    STDOUT << str
  end
  
end

def to_swf(f)	
	f.sub(/\.(mxml|as)/, ".swf")
end

puts html_head( :window_title => "ActionScript 3 Run Command",
                :page_title => "Run" )

if File.exist?(run_file)
  run(run_file)
elsif File.exist?(proj_run_file)
  run(proj_run_file)
elsif File.exist?(proj_default)
  run(proj_default)
elsif File.exist?(proj_flex_out)
  run(proj_flex_out)  
else
  fp = ENV['TM_FILEPATH']
  swf = to_swf(fp)
  if fp != swf && File.exist?(swf)
    run(swf) 
  else
    puts "<h2>Error</h2><p>No file found to run.</p>"
  end
end

html_footer
