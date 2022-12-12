# GUInstallomator
GUI for Installomator

This is a Quick and Dirty Applescript to install software on a macOS device using installomator.
I mostly use this on my test devices that are not (yet) managed and i want quickly have some tools installed without having to reinstall installomator every time. But you can also use it to quickly install/update software without having to open the terminal.

**Why Applescript?**

I wanted to have a portable GUI script with TouchID (for administrator privileges). If i have time i will rewrite this in Swift. But for now it does not require codesigning and it works out of the box on macOS 11+




**How does it work?**

Put it on an USB stick or Airdrop this applescript to a Mac. Doubleclick to open the script in Script Editor and press command + R to run the script.



**Does it require any preinstalled tools/scripts?**

GUIinstallomator will automatically install/update installomator or dockutil if needed



**What does it do exactly?**
>1) Runs privileges.app (if installed) for admin privileges (i mostly work without admin privileges but i do have privileges installed)
>2) Installs or updates Installomator
>3) choose an installomator label from a gui dialog
>4) use TouchID for administrator privileges
>5) Put icon of installed application in Dock


<img src="https://raw.githubusercontent.com/macbofh/GUInstallomator/main/screenshots/choose_label.png" width="256"/> <img src="https://raw.githubusercontent.com/macbofh/GUInstallomator/main/screenshots/touchid.png" width="256"/>
