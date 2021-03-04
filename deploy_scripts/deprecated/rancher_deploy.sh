#!/bin/sh
# this script is most recently tested with Ubuntu Server 20.04 LTS
# this installation is based on a tutorial at https://www.youtube.com/watch?v=oILc0ywDVTk&list=WL&index=41

install_docker(){
    curl https://releases.rancher.com/install-docker/19.03.sh | sh
}

deploy_rancher(){
    docker run -d --restart=unless-stopped \
        -p 80:80 -p 443:443 \
        -v /opt/rancher:/var/lib/rancher \
        --privileged \
        rancher/rancher:latest
}