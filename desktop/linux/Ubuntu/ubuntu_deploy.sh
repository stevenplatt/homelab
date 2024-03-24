#!/bin/sh
# this script is most recently tested with Ubuntu 20.04 LTS

# enable third party repositories 
update_repositories(){
    sudo apt install -y curl
    sudo apt install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    # add Google Cloud SDK repository 
    # https://cloud.google.com/sdk/docs/install#deb
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    
    # add Terraform repository
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    
    sudo apt update -y
}

ubuntu_apps(){
    # Install commmands are on single lines due to issue with installs on certain PopOS releases not working properly
    sudo apt install -y snapd
    sudo apt install -y steam
    sudo apt install -y apt-transport-https 
    sudo apt install -y gnome-tweaks
    sudo apt install -y cmatrix
    sudo apt install -y python3-pip
    sudo apt install -y npm
    sudo apt install -y gimp
    sudo apt install -y inkscape
    sudo apt install -y gnome-boxes
    sudo apt install -y gnome-sushi
    sudo apt install -y transmission
    sudo apt install -y neofetch
    sudo apt install -y numix-icon-theme-circle
    sudo apt install -y tlp
    sudo apt install -y pitivi # installed from ubuntu repo for better compatibility
    sudo apt install -y unrar
    sudo apt install -y ansible
    sudo apt install -y kubectl
    sudo apt install -y deepin-boot-maker
    sudo apt install -y terraform
    sudo apt install -y docker.io #install docker from Ubuntu repository
    sudo apt install -y net-tools # install 'ifconfig' and other tools if not present
    
    # Install additional developer dependencies -- specifically for AWS tools
    sudo apt install -y build-essential 
    sudo apt install -y zlib1g-dev 
    sudo apt install -y libssl-dev 
    sudo apt install -y libncurses-dev 
    sudo apt install -y libffi-dev
    sudo apt install -y libsqlite3-dev 
    sudo apt install -y libreadline-dev 
    sudo apt install -y libbz2-dev
    sudo apt install -y awscli # run 'aws configure' after to input access key information
    sudo apt install -y jq # bash jason parser
    sudo apt install -y kubectl
    
    export KUBE_CONFIG_PATH=~/.kube/config # to allow terraform to find a local kubectl config
    npm install --global yarn # run 'yarn' and then 'yarn build' within the target js directory to activate
    
    # Install Google Cloud SDK's
    # https://cloud.google.com/sdk/docs/install#deb
    sudo apt install -y google-cloud-sdk
    sudo apt install -y google-cloud-sdk-app-engine-python
    sudo apt install -y google-cloud-sdk-app-engine-python-extras
    # sudo apt install -y google-cloud-sdk-app-engine-java
    sudo apt install -y google-cloud-sdk-app-engine-go
    sudo apt install -y google-cloud-sdk-bigtable-emulator
    sudo apt install -y google-cloud-sdk-cbt
    sudo apt install -y google-cloud-sdk-cloud-build-local
    sudo apt install -y google-cloud-sdk-datalab
    sudo apt install -y google-cloud-sdk-datastore-emulator
    sudo apt install -y google-cloud-sdk-firestore-emulator
    sudo apt install -y google-cloud-sdk-pubsub-emulator 
    # run 'gcloud init' to log into the desired Google Cloud project
    # run 'gcloud auth application-default login' to use your local Google credentials to execute API calls
}

# install flatpak apps
flatpak_apps(){
    sudo flatpak install -y flathub us.zoom.Zoom 
    sudo flatpak install -y flathub com.rawtherapee.RawTherapee
    # sudo flatpak install -y flathub org.gnome.Shotwell
    sudo flatpak install -y flathub com.elsevier.MendeleyDesktop
    # sudo flatpak install -y flathub com.skype.Client
    sudo flatpak install -y flathub com.visualstudio.code
    sudo flatpak install -y flathub com.discordapp.Discord
}

# install 3rd Party Applications
external_apps(){
    # install Google Chrome
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
    rm ./google-chrome-stable_current_amd64.deb

    # install Papyrus icon theme
    sudo wget -qO- https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/install.sh | sh

    # install the latest version of the HELM Kubernetes Package Manager
    # https://helm.sh/docs/intro/install/
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    sudo chmod u+x get_helm.sh && ./get_helm.sh
    rm ./get_helm.sh
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
printf "\n\n(Step 1 of 5): Installing Store applications\n"

ubuntu_apps &>> installation.log
# python_apps 

######### Install flatpak applications #########
printf "(Step 2 of 5): Installing Flatpak applications\n"

flatpak_apps &>> installation.log

######### install non-standard repository applications #########
printf "(Step 3 of 5): Installing non-standard repository applications\n"

external_apps &>> installation.log

######### Purge preinstalled Ubuntu applications #########
printf "(Step 4 of 5): Purging preinstalled applications\n"

remove_apps &>> installation.log

######### Upgrade system and applications, then reboot #########
printf "(Step 5 of 5): Installing operating system updates\n"
upgrade_OS &>> installation.log

printf "\nUpdate complete. Rebooting system...\n\n"
sudo reboot

# send terminal output to log using "&>> installation.log". For example "upgrade_OS &>> installation.log"
