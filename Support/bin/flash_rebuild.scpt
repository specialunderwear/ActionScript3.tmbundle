#! /usr/bin/osascript

tell application "Adobe Flash CS3"
	--confirms Flash is the front application
	activate
end tell

tell application "System Events"
	tell process "Adobe Flash CS3"
		-- run the build command
		keystroke return using {command down}
	end tell
end tell
