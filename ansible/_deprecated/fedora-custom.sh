#!/bin/sh
# this script is most recently tested with Fedora 33

# enable third party repositories 
repositories(){
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 
    sudo dnf copr enable dirkdavidis/papirus-icon-theme -y 
    sudo dnf update -y 
}


# install fedora repository utilities and apps
fedora_apps(){
    sudo dnf install -y transmission 
    sudo dnf install -y gnome-tweaks 
    sudo dnf install -y dnf-plugins-core 
    sudo dnf install -y cmatrix 
    sudo dnf install -y liveusb-creator 
    sudo dnf install -y numix-icon-theme-circle 
    sudo dnf install -y papirus-icon-theme 
    sudo dnf install -y npm
    sudo dnf install -y pygtk2
    sudo dnf install -y wireshark 
    sudo dnf install -y nmap 
    sudo dnf install -y unar 
    sudo dnf install -y python3-flask 
    sudo dnf install -y python-virtualenv 
    sudo dnf install -y neofetch 
    sudo dnf install -y tlp
    sudo dnf install -y ansible
    }

# install dependencies for running flask web apps
python_apps(){
    sudo pip3 install flask 
    sudo pip3 install flask-sqlalchemy 
    sudo pip3 install flask-login 
    sudo pip3 install jupyterlab 
    sudo pip3 install notebook
    sudo pip3 install twine
    }

# install flatpak apps
flatpak_apps(){
    sudo flatpak install -y flathub com.elsevier.MendeleyDesktop 
    sudo flatpak install -y flathub org.filezillaproject.Filezilla 
    sudo flatpak install -y flathub com.obsproject.Studio 
    sudo flatpak install -y flathub com.skype.Client
    sudo flatpak install -y flathub com.visualstudio.code 
    sudo flatpak install -y flathub us.zoom.Zoom 
    sudo flatpak install -y flathub com.valvesoftware.Steam 
    sudo flatpak install -y flathub org.inkscape.Inkscape 
    sudo flatpak install -y flathub org.gimp.GIMP 
    sudo flatpak install -y flathub com.github.xournalpp.xournalpp 
    sudo flatpak install -y flathub com.discordapp.Discord
}

# remove preinstalled apps
remove_apps(){
    sudo dnf remove -y rhythmbox* 
    sudo dnf remove -y gnome-contacts* 
    sudo dnf remove -y gnome-maps
}

# apply visual tweaks to the Fedora UI
ui_updates(){
    gsettings set org.gtk.settings.file-chooser show-hidden true
    gsettings set org.gnome.desktop.search-providers disable-external true 
    gsettings set org.gnome.desktop.session idle-delay 900 
    gsettings set org.gnome.desktop.interface clock-show-weekday true
    gsettings set org.gnome.desktop.interface icon-theme 'Numix-Circle' 
    # gsettings set org.gnome.desktop.wm.preferences button-layout "['appmenu:minimize,maximize,close']" # causing issue with close button not showing
    gsettings set org.gnome.nautilus.preferences default-folder-viewer 'icon-view'
    gsettings set org.gnome.nautilus.icon-view default-zoom-level 'standard'
    gsettings set org.gnome.nautilus.preferences thumbnail-limit 100
    gsettings set org.gnome.nautilus.preferences show-image-thumbnails 'always'
    gsettings set org.gnome.desktop.interface show-battery-percentage true
    gsettings set org.gnome.desktop.interface enable animations false
    gsettings set org.gnome.desktop.interface monospace-font-name 'Source Code Pro 11'
    # gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'io.bit3.WhatsAppQT.desktop', 'google-chrome.desktop', 'org.gnome.Terminal.desktop', 'com.visualstudio.code.desktop', 'io.github.jliljebl.Flowblade.desktop', 'com.discordapp.Discord.desktop']"
    gsettings set org.gnome.desktop.privacy remove-old-trash-files true
    gsettings set org.gnome.desktop.privacy remove-old-temp-files true
    gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Shift>F9']"
    gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled false
}

######### run installation script #########

printf "\n\nLoading system customizations...\n"
printf "This process may take up to 30 minutes, depending on network speed.\n\n"

repositories &>> installation.log

printf "\n\n(Step 1 of 4): Installing Fedora applications\n"

fedora_apps &>> installation.log
python_apps &>> installation.log

printf "(Step 2 of 4): Installing Flatpak applications\n"

flatpak_apps &>> installation.log

printf "(Step 3 of 4): Purging preinstalled applications\n"
remove_apps &>> installation.log

printf "(Step 4 of 4): Updating UI preferences\n"
ui_updates &>> installation.log

printf "\nUpdate complete. Rebooting system...\n\n"
sudo reboot
