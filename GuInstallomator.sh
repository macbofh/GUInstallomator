#!/bin/bash

#
# GUI for Installomator
# Sander Schram
#
# version: 19-11-2023
#
# This is a script using Swift Dialog to install software on a macOS device using installomator. 
# I mostly use this on my test devices that are not (yet) managed and i want quickly have some
# tools installed without having to reinstall installomator every time. 
# But you can also use it to quickly install/update software without having to open the terminal.
#
# I Personally put this script in the Script menu in the menubar
#


# Variables
InstallomatorOptions="DEBUG=0 NOTIFY=silent LOGO=jamf"


# MARK: Functions

InstallInstallomator() {
	# install installomator
	InstallomatorURL=$(curl -s https://api.github.com/repos/Installomator/Installomator/releases/latest | grep browser_download_url | cut -d'"' -f4)
	echo "$InstallomatorURL"
	curl -s -L -o /tmp/installomator.pkg "$InstallomatorURL"
	installer -pkg /tmp/Installomator.pkg -target /
	rm /tmp/installomator.pkg
}


# MARK: Main Script

# Check installomator version
gitversion=$(curl -s https://api.github.com/repos/Installomator/Installomator/releases/latest | grep tag_name | cut -d: -f2 | sed 's/v//g' | cut -d'"' -f2 | sed 's/release/.0/g')
installedversion=$(pkgutil --pkg-info com.scriptingosx.Installomator | grep version | cut -d: -f2 | sed 's/ //g')

# Install Installomator if needed or outdated
if [[ ! -f /usr/local/Installomator/Installomator.sh ]] || [[ "$gitversion" != "$installedversion" ]]; then
	InstallInstallomator
fi

softwarelist=$(/usr/local/Installomator/Installomator.sh | tail -n +2 )
first=$(/usr/local/Installomator/Installomator.sh | head -n2 | tail -n1)
values=$(echo $softwarelist | sed 's/ /,/g')

answer=$(/usr/local/bin/dialog \
-m "GuInstallomator" \
--bannertitle "" \
--icon "SF=square.and.arrow.down.on.square.fill" \
--titlefont shadow=1 \
--button1text "Download" \
--button2text "Cancel" \
--selecttitle "Installomator label" \
--selectvalues "$values" \
--selectdefault "$first"
)

label=$( echo $answer | cut -d":" -f2 | cut -d'"' -f2)

if [ "$answer" != "" ]; then

	# run privileges (if installed) for admin privileges
	if [ -f "/Applications/Privileges.app/Contents/Resources/PrivilegesCLI" ]; then
		echo 'guinstallomator' | /Applications/Privileges.app/Contents/Resources/PrivilegesCLI --add
	fi
	sudo /usr/local/Installomator/Installomator.sh $label $InstallomatorOptions > /tmp/guinstallomator.log
	
	AppPath=$(cat /tmp/guinstallomator.log | grep "App(s) found" | tail -n1 | cut -d')' -f2 | cut -d':' -f2 | cut -c2-)
	if [ -d "$AppPath" ]; then
		if [ ! -f /usr/local/bin/dockutil ]; then
			/usr/local/Installomator/Installomator.sh dockutil NOTIFY=silent
		fi
		/usr/local/bin/dockutil --add $AppPath
	fi
fi
