#!/bin/sh
# this script is most recently tested with Ubuntu Server 20.04 LTS

oai_install(){
    # nothing to see here
}

# upgrade Ubuntu OS
upgrade_os(){
    sudo apt update -y
    sudo apt upgrade -y 
    sudo apt autoremove -y
}

######### Welcome message #########
printf "\n\nInstalling Open Air Interface...\n"

oai_install &>> installation.log

######### OS Upgrade #########
printf "\nApplying updates to Ubuntu Server... \n"

uprgade_os &>> installation.log

######### Success Message #########
printf "\nOpen Air Interface deployment complete!\n\n"
