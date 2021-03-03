#!/bin/sh
# this script is most recently tested with Ubuntu Server 20.04 LTS

flexran_install(){
    # nothing to see here
}

# upgrade Ubuntu OS
upgrade_os(){
    sudo apt update -y
    sudo apt upgrade -y 
    sudo apt autoremove -y
}

######### Welcome message #########
printf "\n\nInstalling FlexRAN...\n"

flexran_install &>> installation.log

######### OS Upgrade #########
printf "\nApplying updates to Ubuntu Server... \n"

uprgade_os &>> installation.log

######### Success Message #########
printf "\nFlexRAN deployment complete!\n\n"
