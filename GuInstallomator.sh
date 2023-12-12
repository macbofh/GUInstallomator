#!/bin/zsh

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
# Rewritten from Applescript. 
# With help from https://github.com/Installomator/Installomator/blob/main/MDM/swiftdialog_example.sh
#

#

# export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# Variables
InstallomatorOptions="DEBUG=0 NOTIFY=silent LOGO=jamf"
installomator="/usr/local/Installomator/Installomator.sh"
dialog="/usr/local/bin/dialog"
dialog_command_file="/var/tmp/dialog.log"


# MARK: Functions

InstallInstallomator() {
	# install installomator
	InstallomatorURL=$(curl -s https://api.github.com/repos/Installomator/Installomator/releases/latest | grep browser_download_url | cut -d'"' -f4)
	echo "$InstallomatorURL"
	curl -s -L -o /tmp/installomator.pkg "$InstallomatorURL"
	installer -pkg /tmp/Installomator.pkg -target /
	rm /tmp/installomator.pkg
}

dialogUpdate() {
    # $1: dialog command
    local dcommand=$1

    if [[ -n $dialog_command_file ]]; then
        echo "$dcommand" >> $dialog_command_file
        echo "Dialog: $dcommand"
    fi
}

progressUpdate() {
    # $1: progress text (optional)
    local text=$1
    itemCounter=$((itemCounter + 1))
    dialogUpdate "progress: $itemCounter"
    if [[ -n $text ]]; then
        dialogUpdate "progresstext: $text"
    fi
}

startItem() {
    local description=$1

    echo "Starting Item: $description"
    dialogUpdate "listitem: $description: wait"
    progressUpdate $description
}

cleanupAndExit() {
    # kill caffeinate process
    if [[ -n $caffeinatePID ]]; then
        echo "killing caffeinate..."
        kill $caffeinatePID
    fi

    # clean up tmp dir
    if [[ -n $tmpDir && -d $tmpDir ]]; then
        echo "removing tmpDir $tmpDir"
        rm -rf $tmpDir
    fi
}



# MARK: Main Script

# Check installomator version
gitversion=$(curl -s https://api.github.com/repos/Installomator/Installomator/releases/latest | grep tag_name | cut -d: -f2 | sed 's/v//g' | cut -d'"' -f2 | sed 's/release/.0/g')
installedversion=$(pkgutil --pkg-info com.scriptingosx.Installomator | grep version | cut -d: -f2 | sed 's/ //g')

# Install Installomator if needed or outdated
if [[ ! -f /usr/local/Installomator/Installomator.sh ]] || [[ "$gitversion" != "$installedversion" ]]; then
	InstallInstallomator
fi


if [ ! -f /usr/local/bin/dialog ]; then
	/usr/local/Installomator/Installomator.sh dialog $InstallomatorOptions
fi



values=$(/usr/local/Installomator/Installomator.sh | tail -n +2 | tr '\n' ',')
first=$(/usr/local/Installomator/Installomator.sh | head -n2 | tail -n1)

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


installomatorlabel=$( echo $answer | head -n1 | cut -d":" -f2 | cut -d'"' -f2)

echo $installomatorlabel



if [ "$answer" != "" ]; then

	# run privileges (if installed) for admin privileges
	if [ -f "/Applications/Privileges.app/Contents/Resources/PrivilegesCLI" ]; then
		echo 'guinstallomator' | /Applications/Privileges.app/Contents/Resources/PrivilegesCLI --add
	fi
	

	# display first screen
	 $dialog --title "Installing $installomatorlabel" \
			--message "Installing $installomatorlabel" \
			--hideicon \
			--mini \
			--progress 100 \
			--position bottomright \
			--ontop \
			--movable \
			--commandfile $dialog_command_file & dialogPID=$!

	sleep 0.1

	echo $installomatorlabel



	sudo /usr/local/Installomator/Installomator.sh $installomatorlabel DIALOG_CMD_FILE="$dialog_command_file" NOTIFY=silent > /tmp/guinstallomator.log

	# clean up UI

	dialogUpdate "progress: complete"
	dialogUpdate "progresstext: Done"

	sleep 0.5

	dialogUpdate "quit:"

	AppPath=$(cat /tmp/guinstallomator.log | grep "App(s) found" | tail -n1 | cut -d')' -f2 | cut -d':' -f2 | cut -c2-)
	if [ -d "$AppPath" ]; then
		if [ ! -f /usr/local/bin/dockutil ]; then
			/usr/local/Installomator/Installomator.sh dockutil $InstallomatorOptions
		fi
		/usr/local/bin/dockutil --add $AppPath
	fi
fi
