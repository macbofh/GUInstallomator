--
-- Sander Schram
--
-- version: 22-07-2021
--


-- FUNCTIONS

to installInstallomator()
	--
	-- Install latest version of Installomator
	--
	--display dialog "Installomator will be installed/updated." buttons {"OK"} default button "OK"
	set pkgurl to do shell script "curl -s https://api.github.com/repos/Installomator/Installomator/releases/latest | python -c 'import json,sys;obj=json.load(sys.stdin);print obj[\"assets\"][0][\"browser_download_url\"]'"
	do shell script "curl -L -o /tmp/installomator.pkg " & pkgurl
	do shell script "installer -pkg /tmp/Installomator.pkg -target /" with administrator privileges
	-- enable all notifications
	do shell script "sed -i -e 's/NOTIFY=success/NOTIFY=all/g' /usr/local/Installomator/Installomator.sh" with administrator privileges
end installInstallomator

to installDockUtil()
	--
	-- Install latest version of DockUtil
	--
	display dialog "Dockutil will be installed." buttons {"OK"} default button "OK"
	set pkgurl to do shell script "curl -s https://api.github.com/repos/kcrawford/dockutil/releases/latest | python -c 'import json,sys;obj=json.load(sys.stdin);print obj[\"assets\"][0][\"browser_download_url\"]'"
	do shell script "curl -L -o /tmp/dockutil.pkg " & pkgurl
	do shell script "installer -pkg /tmp/dockutil.pkg -target /" with administrator privileges
end installDockUtil


-- MAIN APPLESCRIPT

activate

tell application "System Events"
	if not (exists file "/usr/local/Installomator/Installomator.sh") then
		installInstallomator
	else
		-- installomator is installed, run versioncheck....
		set installed_version to do shell script "pkgutil --pkg-info com.scriptingosx.Installomator | grep version | cut -d: -f2 | sed 's/ //g'"
		set git_version to do shell script "curl -s https://api.github.com/repos/Installomator/Installomator/releases/latest | grep tag_name | cut -d: -f2 | sed 's/v//g' | cut -d'\"' -f2"
		if git_version is greater than installed_version then
			set antwoord to button returned of (display dialog "There is a newer version of Installomator available.
- You have version " & installed_version & " installed.
- The lastest online version is " & git_version buttons {"Update", "Continue"} default button "Update")
			if antwoord is "Update" then
				my installInstallomator()
			end if
		end if
		
	end if
end tell
activate
set label to choose from list (paragraphs of (do shell script "/usr/local/Installomator/Installomator.sh | tail -n +2"))

if label ­ false then
	do shell script "rm -f /var/log/Installomator.log" with administrator privileges
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
				installDockUtil
			end if
		end tell
		try
			do shell script "/usr/local/bin/dockutil --add '" & appPath & "'"
		end try
	else
		display dialog "Kan app '" & appPath & "' niet toevoegen aan de Dock." buttons {"OK"} default button "OK"
	end if
	
	display notification "End GuInstallomator - Label: " & label
end if
