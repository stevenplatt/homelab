#!/bin/sh
# this script is most recently tested with Ubuntu Server 20.04 LTS

# download and install deb from google reposiory 
install_minikube(){
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
    sudo dpkg -i minikube_latest_amd64.deb
    # start minikube
    minikube start
    # instruct minikube to download lastest version of kubectl
    minikube kubectl -- get po -A
    # start kubernetes dashboard and return the URL location
    dash_url=$(minikube dashboard --url)
}

# upgrade Ubuntu OS
upgrade_os(){
    sudo apt update -y
    sudo apt upgrade -y 
    sudo apt autoremove -y
}

######### Welcome message #########
printf "\n\nLoading minikube installation...\n"

install_minikube &>> installation.log

######### OS Upgrade #########
printf "\nApplying updates to Ubuntu Server... \n"

uprgade_os &>> installation.log

######### Success Message #########
printf "\nminikube installation complete: $dash_url \n\n"
