#!/bin/sh
# this script is most recently tested with Ubuntu 20.04 LTS

# enable third party repositories 
update_repositories(){
    sudo apt install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

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
    sudo apt install -y unrar
    sudo apt install -y ansible
}

# install dependencies for running flask web apps
# python_apps(){
#     sudo pip3 install flask 
#     sudo pip3 install flask-sqlalchemy 
#     sudo pip3 install flask-login
#     sudo pip3 install twine
#     sudo pip3 install seaborn
#     }

# install flatpak apps
flatpak_apps(){
    sudo flatpak install -y flathub us.zoom.Zoom 
    sudo flatpak install -y flathub com.rawtherapee.RawTherapee
    # sudo flatpak install -y flathub org.gnome.Shotwell
    sudo flatpak install -y flathub com.elsevier.MendeleyDesktop
    # sudo flatpak install -y flathub com.skype.Client
    sudo flatpak install -y flathub com.visualstudio.code
    sudo flatpak install -y flathub org.inkscape.Inkscape
    sudo flatpak install -y flathub org.gimp.GIMP
    sudo flatpak install -y flathub com.discordapp.Discord
}

# install snap apps
snap_apps(){
    sudo snap install kubectl --classic # Kubernetes CLI
    sudo snap install doctl # Digital Ocean CLI
    sudo snap install aws-cli --classic # AWS CLI
    sudo snap install google-cloud-sdk --classic # Google Cloud CLI
    sudo snap install terraform --candidate # Terraform CLI
}

# install 3rd Party Applications
external_apps(){
    # install Google Chrome
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
    rm ./google-chrome-stable_current_amd64.deb

    # belenaEtcher: https://www.fossmint.com/etcher-usb-sd-card-bootable-image-creator-for-linux/
    echo "deb https://deb.etcher.io stable etcher" | sudo tee /etc/apt/sources.list.d/balena-etcher.list
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 379CE192D401AB61
    sudo apt update
    sudo apt install -y balena-etcher-electron

    # install Papyrus icon theme
    sudo wget -qO- https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/install.sh | sh

    # install the latest version of the HELM Kubernetes Package Manager
    # https://helm.sh/docs/intro/install/
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | sh
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

update_repositories &>> installation.log

######### Install store applications #########
printf "\n\n(Step 1 of 6): Installing Store applications\n"

ubuntu_apps &>> installation.log
# python_apps 

######### Install flatpak applications #########
printf "(Step 2 of 6): Installing Flatpak applications\n"

flatpak_apps &>> installation.log

######### Install snap applications #########
printf "(Step 3 of 6): Installing Snap applications\n"

snap_apps &>> installation.log

######### install non-standard repository applications #########
printf "(Step 4 of 6): Installing non-standard repository applications\n"

external_apps &>> installation.log

######### Purge preinstalled Ubuntu applications #########
printf "(Step 5 of 6): Purging preinstalled applications\n"

remove_apps &>> installation.log

######### Upgrade system and applications, then reboot #########
printf "(Step 6 of 6): Installing operating system updates\n"
upgrade_OS &>> installation.log

printf "\nUpdate complete. Rebooting system...\n\n"
sudo reboot

# send terminal output to log using "&>> installation.log". For example "upgrade_OS &>> installation.log"
