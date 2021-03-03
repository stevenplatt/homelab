#!/bin/sh
# this script is most recently tested with Proxmox VE 6.3

# download system images to the Proxmox iso directory
download_images(){
    cd /var/lib/vz/template/iso
    wget https://releases.ubuntu.com/20.04/ubuntu-20.04.2.0-desktop-amd64.iso
    wget https://nyifiles.netgate.com/mirror/downloads/pfSense-CE-2.5.0-RELEASE-amd64.iso.gz
    wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
    cd
}

######### Welcome message #########
printf "\n\nDownloading operating system images...\n"

download_images

######### Success Message #########
printf "\nImage downloads complete\n\n"
