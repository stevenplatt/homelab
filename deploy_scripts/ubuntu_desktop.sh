#!/bin/sh
# this script is most recently tested with Ubuntu 20.04 LTS

# enable third party repositories 
update_repositories(){
    sudo apt install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    # belenaEtcher: https://www.fossmint.com/etcher-usb-sd-card-bootable-image-creator-for-linux/
    echo "deb https://deb.etcher.io stable etcher" | sudo tee /etc/apt/sources.list.d/balena-etcher.list
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 379CE192D401AB61

    sudo apt update -y
}

ubuntu_apps(){
    sudo apt install -y snapd
    sudo apt install -y steam
    sudo apt install -y apt-transport-https 
    sudo apt install -y gnome-tweaks
    sudo apt install -y cmatrix
    sudo apt install -y python3-pip
    sudo apt install -y npm
    sudo apt install -y gnome-boxes
    sudo apt install -y gnome-sushi
    sudo apt install -y transmission
    sudo apt install -y neofetch
    sudo apt install -y numix-icon-theme-circle
    sudo apt install -y tlp
    sudo apt install -y pitivi # installed from ubuntu repo for better compatibility
    sudo apt install -y obs-studio # installed from ubuntu repo for better compatibility
    sudo apt install -y balena-etcher-electron
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
    sudo flatpak install -y flathub org.filezillaproject.Filezilla 
    sudo flatpak install -y flathub us.zoom.Zoom 
    sudo flatpak install -y flathub com.rawtherapee.RawTherapee
    sudo flatpak install -y flathub org.gnome.Shotwell
    sudo flatpak install -y flathub com.elsevier.MendeleyDesktop
    sudo flatpak install -y flathub com.skype.Client
    sudo flatpak install -y flathub com.visualstudio.code
    sudo flatpak install -y flathub org.inkscape.Inkscape
    sudo flatpak install -y flathub org.gimp.GIMP
    sudo flatpak install -y flathub com.discordapp.Discord
}

# install snap apps
snap_apps(){
    sudo snap install kubectl --classic
}

# install obs studio
obs_install(){
    # source instruction: https://snapcraft.io/obs-studio
    sudo snap install obs-studio
    
    # connect media interfaces
    sudo snap connect obs-studio:alsa
    sudo snap connect obs-studio:audio-record
    sudo snap connect obs-studio:avahi-control
    sudo snap connect obs-studio:camera
    sudo snap connect obs-studio:jack1
    sudo snap connect obs-studio:kernel-module-observe
    
    # enable virtual camera support
    sudo snap connect obs-studio:kernel-module-observe
    sudo apt -y install v4l2loopback-dkms v4l2loopback-utils
    echo "options v4l2loopback devices=1 video_nr=13 card_label='OBS Virtual Camera'    exclusive_caps=1" | sudo tee /etc/modprobe.d/v4l2loopback.conf
    echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf
    sudo modprobe -r v4l2loopback
    sudo modprobe v4l2loopback devices=1 video_nr=13 card_label='OBS Virtual Camera' exclusive_caps=1
    
    # enable removable media support
    snap connect obs-studio:removable-media
    
    # allow usb dslr support
    snap connect obs-studio:raw-usb
    
    # allow input overlay support
    snap connect obs-studio:joystick
}

# install 3rd Party Applications
external_apps(){
    # install Google Chrome
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
    rm ./google-chrome-stable_current_amd64.deb

    # install TeamViewer
    # wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
    # sudo apt install -y ./teamviewer_amd64.deb
    # rm ./teamviewer_amd64.deb

    # install Papyrus icon theme
    sudo wget -qO- https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/install.sh | sh
}

# remove preinstalled apps
remove_apps(){
    sudo apt-get purge --auto-remove -y geary*
    sudo apt-get purge --auto-remove -y rhythmbox* 
    sudo apt-get purge --auto-remove -y gnome-contacts* 
    sudo apt-get purge --auto-remove -y gnome-maps
    sudo apt-get purge --auto-remove -y firefox*
}

# upgrade Ubuntu OS
upgrade_OS(){
    sudo apt upgrade -y 
    sudo apt autoremove -y
}


######### Welcome message #########
printf "\n\nLoading system customizations...\n"
printf "This process may take up to 30 minutes, depending on network speed.\n\n"

update_repositories

######### Install store applications #########
printf "\n\n(Step 1 of 5): Installing Store applications\n"

ubuntu_apps 
# python_apps 

######### Install flatpak applications #########
printf "(Step 2 of 5): Installing Flatpak applications\n"

# flatpak_apps 

######### Install snap applications #########
printf "(Step 3 of 5): Installing Snap applications\n"

snap_apps
# obs_install

######### install non-standard repository applications #########
# printf "(Step 3 of 5): Installing non-standard repository applications\n"

# external_apps &>> installation.log

######### Purge preinstalled Ubuntu applications #########
printf "(Step 4 of 5): Purging preinstalled applications\n"

remove_apps

######### Upgrade system and applications, then reboot #########
printf "(Step 5 of 5): Upgrading Ubuntu base distribution image\n"
upgrade_OS 

printf "\nUpdate complete. Rebooting system...\n\n"
sudo reboot

# send terminal output to log using "&>> installation.log". For example "upgrade_OS &>> installation.log"
