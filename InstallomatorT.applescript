--
-- Sander Schram
--
-- version: 20-07-2021
--


tell application "System Events"
	if not (exists file "/usr/local/Installomator/Installomator.sh") then
		display dialog "Geen installomator gevonden, downloaden"
		set pkgurl to do shell script "curl -s https://api.github.com/repos/Installomator/Installomator/releases/latest | python -c 'import json,sys;obj=json.load(sys.stdin);print obj[\"assets\"][0][\"browser_download_url\"]'"
		do shell script "curl -L -o /tmp/installomator.pkg " & pkgurl
		activate
		do shell script "installer -pkg /tmp/Installomator.pkg -target /" with administrator privileges
		-- enable all notifications
		do shell script "sed -i -e 's/NOTIFY=success/NOTIFY=all/g' /usr/local/Installomator/Installomator.sh" with administrator privileges
	end if
end tell

activate
set label to choose from list (paragraphs of (do shell script "/usr/local/Installomator/Installomator.sh | tail -n +2"))

if label ­ false then
	do shell script "rm /var/log/Installomator.log" with administrator privileges
	do shell script "/usr/local/Installomator/Installomator.sh " & label with administrator privileges
	
	-- zoek app path ahv "/Applications" vermelding in log
	set appPath to "/" & (do shell script "cat /private/var/log/Installomator.log | grep 'found app at /' | cut -d',' -f1 | cut -d'/' -f2-")
	if appPath = "/" then
		-- zoek app path ahv "App naam" vermelding in log
		set appPath to "/Applications/" & (do shell script "cat /private/var/log/Installomator.log | grep 'Latest version of ' | awk 'BEGIN {FS=\" of \";}{print $2}' | awk 'BEGIN {FS=\" is \";}{print $1}'") & ".app"
	end if
	
	-- bestaat app echt op deze locatie?
	tell application "System Events" to set pathisValid to exists disk item appPath
	if pathisValid then
		-- icon in Dock	
		tell application "System Events"
			if not (exists file "/usr/local/bin/dockutil") then
				display dialog "Geen dockutil gevonden, downloaden"
				set pkgurl to do shell script "curl -s https://api.github.com/repos/kcrawford/dockutil/releases/latest | python -c 'import json,sys;obj=json.load(sys.stdin);print obj[\"assets\"][0][\"browser_download_url\"]'"
				
				do shell script "curl -L -o /tmp/dockutil.pkg " & pkgurl
				activate
				do shell script "installer -pkg /tmp/dockutil.pkg -target /" with administrator privileges
			end if
		end tell
		try
			do shell script "/usr/local/bin/dockutil --add '" & appPath & "'"
		end try
	else
		display dialog "Kan app '" & appPath & "' niet toevoegen aan de Dock."
	end if
end if
