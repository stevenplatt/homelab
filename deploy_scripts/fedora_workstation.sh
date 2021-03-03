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

######### run installation script #########

printf "\n\nLoading system customizations...\n"
printf "This process may take up to 30 minutes, depending on network speed.\n\n"

repositories &>> installation.log

printf "\n\n(Step 1 of 3): Installing Fedora applications\n"

fedora_apps &>> installation.log
python_apps &>> installation.log

printf "(Step 2 of 3): Installing Flatpak applications\n"

flatpak_apps &>> installation.log

printf "(Step 3 of 3): Purging preinstalled applications\n"
remove_apps &>> installation.log

printf "\nUpdate complete. Rebooting system...\n\n"
sudo reboot