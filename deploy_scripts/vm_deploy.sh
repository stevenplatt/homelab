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

# deploy VMs
# https://forum.proxmox.com/threads/vm-create-edit-delete-with-api.37743/
# https://gist.github.com/dragolabs/f391bdda050480871ddd129aa6080ac2


#  pvesh create /nodes/proxmox/qemu -name pop-os-tester02 -vmid 121 \
#             -scsi0 local-lvm:32 \
#             -memory 8192 -cpu host -socket 1 -cores 4 \
#             -net0 virtio,bridge=vmbr0 \
#             -ide2 local:iso/pop-os_20.10_amd64_intel_14.iso,media=cdrom

######### Welcome message #########
printf "\n\nDownloading operating system images...\n"

download_images

######### Success Message #########
printf "\nImage downloads complete\n\n"
