#!/bin/sh
# this script is most recently tested with Fedora 33

# enable third party repositories 
repositories(){
    sudo dnf install -y dnf-plugins-core
    sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm # rpmfusion free repo
    sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm # rpmfusion non-free repo
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 
    sudo dnf copr enable dirkdavidis/papirus-icon-theme -y 
    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo # source: https://www.terraform.io/downloads
    sudo dnf update -y 
}

# install fedora repository utilities and apps
fedora_apps(){
    sudo dnf install -y gnome-tweaks
    sudo dnf install -y cmatrix
    sudo dnf install -y numix-icon-theme-circle 
    sudo dnf install -y papirus-icon-theme 
    sudo dnf install -y npm
    sudo dnf install -y pygtk2
    sudo dnf install -y nmap 
    sudo dnf install -y unar 
    sudo dnf install -y python3-flask 
    sudo dnf install -y python-virtualenv 
    sudo dnf install -y neofetch 
    sudo dnf install -y powerline 
    sudo dnf install -y powerline-fonts
    sudo dnf install -y ansible
    sudo dnf install -y pitivi
    sudo dnf install -y steam
    sudo dnf install -y inkscape
    sudo dnf install -y gimp
    sudo dnf install -y snapd && sudo ln -s /var/lib/snapd/snap /snap
    sudo dnf install -y terraform
    yarn install --ignore-engines # for javascript builds
    # jq is installed already in stock fedora 36
    # sudo dnf instal -y jq
    }
    
# install multimedia codecs from rpmfusion (required for pitivi and certain video playback)
# https://docs.fedoraproject.org/en-US/quick-docs/assembly_installing-plugins-for-playing-movies-and-music/
multimedia_apps(){
    sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel
    sudo dnf install -y lame\* --exclude=lame-devel
    sudo dnf group upgrade -y --with-optional Multimedia
    }

# install dependencies for running flask web apps
python_apps(){
    sudo pip3 install flask 
    sudo pip3 install flask-sqlalchemy 
    sudo pip3 install flask-login
    sudo pip3 install twine
    sudo pip3 install psutil
    }

# install flatpak apps
flatpak_apps(){
    sudo flatpak install -y flathub com.elsevier.MendeleyDesktop 
    # sudo flatpak install -y flathub org.filezillaproject.Filezilla 
    # sudo flatpak install -y flathub com.obsproject.Studio 
    # sudo flatpak install -y flathub com.skype.Client
    sudo flatpak install -y flathub com.visualstudio.code 
    sudo flatpak install -y flathub us.zoom.Zoom
    sudo flatpak install -y flathub com.discordapp.Discord
    sudo flatpak install -y flathub com.google.Chrome
    sudo flatpak install -y flathub com.slack.Slack
}

# install external apps
external_apps(){
    # install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh

    # run docker without requiring sudo command
    # source: https://docs.docker.com/engine/install/linux-postinstall/
    sudo groupadd docker
    sudo usermod -aG docker $USER 
    newgrp docker
    sudo systemctl enable docker.service # add doker to startup
    sudo systemctl enable containerd.service
    
    # install yarn for javascript builds
    sudo npm install --global yarn

    # install helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

# install google cloud cli items
google_cloud_cli(){
    # source: https://cloud.google.com/sdk/docs/install#rpm

    # update the google cloud repository
    cat "[google-cloud-cli]
    name=Google Cloud CLI
    baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
    enabled=1
    gpgcheck=1
    repo_gpgcheck=0
    gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
           https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" >> /etc/yum.repos.d/google-cloud-sdk.repo
    
    # install google cloud cli dependencies
    sudo dnf install -y libxcrypt-compat.x86_64

    # install google cloud cli items
    sudo dnf install -y google-cloud-cli
    sudo dnf install -y google-cloud-cli-anthos-auth
    sudo dnf install -y google-cloud-cli-app-engine-go
    sudo dnf install -y google-cloud-cli-app-engine-grpc
    sudo dnf install -y google-cloud-cli-app-engine-java
    sudo dnf install -y google-cloud-cli-app-engine-python
    sudo dnf install -y google-cloud-cli-app-engine-python-extras
    sudo dnf install -y google-cloud-cli-bigtable-emulator
    sudo dnf install -y google-cloud-cli-cbt
    sudo dnf install -y google-cloud-cli-cloud-build-local
    sudo dnf install -y google-cloud-cli-cloud-run-proxy
    sudo dnf install -y google-cloud-cli-config-connector
    sudo dnf install -y google-cloud-cli-datalab
    sudo dnf install -y google-cloud-cli-datastore-emulator
    sudo dnf install -y google-cloud-cli-firestore-emulator
    sudo dnf install -y google-cloud-cli-gke-gcloud-auth-plugin
    sudo dnf install -y google-cloud-cli-kpt
    sudo dnf install -y google-cloud-cli-kubectl-oidc
    sudo dnf install -y google-cloud-cli-local-extract
    sudo dnf install -y google-cloud-cli-minikube
    sudo dnf install -y google-cloud-cli-nomos
    sudo dnf install -y google-cloud-cli-pubsub-emulator
    sudo dnf install -y google-cloud-cli-skaffold
    sudo dnf install -y google-cloud-cli-spanner-emulator
    sudo dnf install -y google-cloud-cli-terraform-validator
    sudo dnf install -y google-cloud-cli-tests
    sudo dnf install -y kubectl && export KUBE_CONFIG_PATH=~/.kube/config 
    # ^^ required for terraform to read the current kubernetes context
    # to initialize and auth the google cloud cli after install - run "gcloud init"
    # to specific a default google account auth - run "gcloud auth application-default login"
}

# install the aws cli, source: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
aws_cli(){
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws
    # to provide authentication keys to the AWS CLI after installation - run "aws configure"
    # source: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html
}

# install and configura tools for proper laptop battery life control
# source: https://www.tecmint.com/tlp-increase-and-optimize-linux-battery-life/
power_management(){
    # install and configure auto-cpufreq
    # source: https://github.com/AdnanHodzic/auto-cpufreq
    sudo snap install auto-cpufreq
    sudo auto-cpufreq --install
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq/auto_cpufreq
    sudo python3 power_helper.py --gnome_power_disable performance
    sudo python3 power_helper.py --gnome_power_disable balanced
    cd ../../
    rm -rf auto-cpufreq/
}

system_customization(){
    # configure git user
    git config --global user.name "$(echo -n "U3RldmVuIFBsYXR0" | base64 --decode)"
    git config --global user.email "$(echo -n "bXIucGxhdHRAZ21haWwuY29t" | base64 --decode)"

    # update dnf for faster downloads
    # source: https://morioh.com/p/39ab4498b92d
    sudo echo fastestmirror=1 | sudo tee -a /etc/dnf/dnf.conf
    sudo echo max_parallel_downloads=10 | sudo tee -a /etc/dnf/dnf.conf

    # enable powerline fonts in terminal
    # source: https://fedoramagazine.org/add-power-terminal-powerline/
    cat "if [ -f `which powerline-daemon` ]; then
    powerline-daemon -q
    POWERLINE_BASH_CONTINUATION=1
    POWERLINE_BASH_SELECT=1
    . /usr/share/powerline/bash/powerline.sh
    fi" >> ~/.bashrc
}

# remove preinstalled apps
remove_apps(){
    sudo dnf remove -y rhythmbox* 
    sudo dnf remove -y gnome-contacts* 
    sudo dnf remove -y gnome-maps
}

# disable crash reporting and alerting
# https://robbinespu.gitlab.io/blog/2019/05/15/disabling-abrt-fedora/
disable_alerts(){ 
    sudo systemctl stop abrt-journal-core.service 
    sudo systemctl disable  abrt-journal-core.service

    sudo systemctl stop abrt-oops.service
    sudo systemctl disable abrt-oops.service

    sudo systemctl stop abrt-xorg.service
    sudo systemctl disable abrt-xorg.service

    sudo systemctl stop abrtd.service
    sudo systemctl disable abrtd.service
}

create_swapfile(){
    # create a swapfile required for hibernation to work
    # source: https://superuser.com/questions/1067150/how-to-create-swapfile-on-ssd-disk-with-btrfs/1411462#1411462
    # secondary source: https://gist.github.com/eloylp/b0d64d3c947dbfb23d13864e0c051c67
    file='/swapfile'
    sudo touch "$file"
    sudo chattr +C "$file" # no copy-on-write
    sudo dd if=/dev/zero of="$file" bs=1G count=40 # allocate 40 GB 
    sudo chmod 600 "$file"
    sudo mkswap "$file"
    sudo chown root "$file"
    sudo swapon "$file" # activate swapfile
}

######### run installation script #########

printf "\n\nLoading system customizations...\n"
printf "This process may take up to 30 minutes, depending on network speed.\n\n"

repositories &>> installation.log

printf "\n\nInstalling Fedora applications\n"

fedora_apps &> installation.log
multimedia_apps &> installation.log
python_apps &> installation.log
external_apps &> installation.log

printf "Installing Flatpak applications\n"

flatpak_apps &> installation.log

printf "Installing CLI tools\n"
google_cloud_cli &> installation.log
aws_cli &> installation.log

printf "Applying system customizations\n"
power_management &> installation.log
remove_apps &> installation.log
disable_alerts &> installation.log
system_customization &> installation.log

printf "\nUpdate complete. Rebooting system...\n\n"
sleep 5
sudo reboot
