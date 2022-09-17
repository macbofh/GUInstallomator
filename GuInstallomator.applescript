--
-- Quick and Dirty Applescript GUI for Installomator
-- Sander Schram
--
-- version: 19-07-2022
--

-- FUNCTIONS

to installInstallomator()
	--
	-- Install latest version of Installomator
	--
	activate
	--display dialog "start install"
	set pkgurl to do shell script "curl -s https://api.github.com/repos/Installomator/Installomator/releases/latest | grep browser_download_url | cut -d'\"' -f4  "
	do shell script "curl -L -o /tmp/installomator.pkg " & pkgurl
	do shell script "installer -pkg /tmp/Installomator.pkg -target /" with administrator privileges
end installInstallomator



-- MAIN APPLESCRIPT

activate




tell application "System Events"
	-- run privileges
	if (exists file "/Applications/Privileges.app/Contents/Resources/PrivilegesCLI") then
		do shell script "echo 'guiinstallomator' | /Applications/Privileges.app/Contents/Resources/PrivilegesCLI --add"
	end if
	
	-- Install Installomator if not already installed
	set git_version to do shell script "curl -s https://api.github.com/repos/Installomator/Installomator/releases/latest | grep tag_name | cut -d: -f2 | sed 's/v//g' | cut -d'\"' -f2 | sed 's/release/.0/g'"
	if not (exists file "/usr/local/Installomator/Installomator.sh") then
		-- installomator not installed, start install
		--display dialog "not installed"
		my installInstallomator()
	end if
	
	-- Update Installomator if outdated
	set installed_version to do shell script "pkgutil --pkg-info com.scriptingosx.Installomator | grep version | cut -d: -f2 | sed 's/ //g'"
	if git_version is greater than installed_version then
		set antwoord to button returned of (display dialog "There is a newer version of Installomator available.
- You have version " & installed_version & " installed.
- The lastest online version is " & git_version buttons {"Update", "Continue"} default button "Update")
		if antwoord is "Update" then
			my installInstallomator()
		end if
	end if
end tell

activate
-- Select app from installomator label list
set label to choose from list (paragraphs of (do shell script "/usr/local/Installomator/Installomator.sh | tail -n +2"))

if label ­ false then
	-- Install app using installomator
	do shell script "rm -f /var/log/Installomator.log" with administrator privileges
	do shell script "/usr/local/Installomator/Installomator.sh " & label & " NOTIFY=silent" with administrator privileges
	
	-- search app using "/Applications" in log
	set appPath to "/" & (do shell script "cat /private/var/log/Installomator.log | grep 'found app at /' | cut -d',' -f1 | cut -d'/' -f2- | tail -n1")
	if appPath = "/" then
		-- search app path using "App name" in log
		set appPath to "/Applications/" & (do shell script "cat /private/var/log/Installomator.log | grep 'Latest version of ' | awk 'BEGIN {FS=\" of \";}{print $2}' | awk 'BEGIN {FS=\" is \";}{print $1}'") & ".app"
	end if
	
	-- Does app exist on this path?
	tell application "System Events" to set pathisValid to exists disk item appPath
	if pathisValid then
		tell application "System Events"
			if not (exists file "/usr/local/bin/dockutil") then
				-- install dockutil if not already installed
				do shell script "/usr/local/Installomator/Installomator.sh dockutil NOTIFY=silent" with administrator privileges
			end if
		end tell
		try
			-- add icon to Dock using dockutil
			do shell script "/usr/local/bin/dockutil --add '" & appPath & "'"
		end try
	end if
	-- show end notification
	display notification "End GuInstallomator - Label: " & label
end if
