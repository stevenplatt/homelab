# this script installs configurations required to run deployKF (kubeflow)
# source: https://www.deploykf.org/guides/local-quickstart/

# run: sudo ./fedora_deployKF.sh

install_flatpaks () {
    printf "installing flatpak applications... \n"
    flatpak install -y flathub com.visualstudio.code
    flatpak install -y flathub com.google.Chrome
    flatpak install -y flathub io.podman_desktop.PodmanDesktop
    printf "flatpak installations are complete! \n"
}

install_brew () {
    printf "installing Homebrew for Linux... \n"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    printf "adding brew to PATH... \n"
    (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/telecomsteve/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

    printf "installing brew dependencies... \n"
    sudo yum groupinstall 'Development Tools' && brew install gcc
    printf "Homebrew installation complete! \n"
}

install_docker_engine () {
    # source: https://docs.docker.com/engine/install/fedora/
    printf "installing Docker engine... \n"
    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo chmod 666 /var/run/docker.sock
    sudo systemctl start docker
    printf "Docker engine installation complete! \n"
}

install_deployKF_deps () {
    printf "installing deployKF (kubeflow) dependencies... \n"
    brew install argocd kubectl k3d k9s # 'kind' is also available
    printf "deployKF dependency installation complete! \n"
}

check_and_append_sysctl() {
    # !!! does not work within script !!!
    printf "updating inotify limits... \n"
    local line1="fs.inotify.max_user_instances=1280"
    local line2="fs.inotify.max_user_watches=655360"

    sudo grep -qF "$line1" /etc/sysctl.conf || sudo echo "$line1" >> /etc/sysctl.conf
    sudo grep -qF "$line2" /etc/sysctl.conf || sudo echo "$line2" >> /etc/sysctl.conf

    sudo sysctl -p
    printf "inotify updates complete! \n"
}

create_k3d_cluster () {
    k3d cluster create "deploykf" --image "rancher/k3s:v1.27.10-k3s2"
}

install_argoCD () {
    printf "deploying ArgoCD to k3d cluster... \n"
    git clone -b main https://github.com/deployKF/deployKF.git ./deploykf
    chmod +x ./deploykf/argocd-plugin/install_argocd.sh
    bash ./deploykf/argocd-plugin/install_argocd.sh

    printf "cleaning up ArgoCD deployment code... \n"
    rm -rf ./deploykf
    printf "ArgoCD deployment is complete! \n"
}

deploy_deployKF () {
    printf "deploying deployKF application stack using ArgoCD... \n"
    kubectl apply -f ./deploykf-app-of-apps.yaml

    printf "initializing ArgoCD application sync... \n"
    git clone -b main https://github.com/deployKF/deployKF.git ./deploykf
    chmod +x ./deploykf/scripts/sync_argocd_apps.sh
    bash ./deploykf/scripts/sync_argocd_apps.sh
    rm -rf ./deploykf
}

expose_deployKF () {

    # !!! does not work within script !!!
    # printf "updating /etc/hosts... \n"
    # local host_1="127.0.0.1 deploykf.example.com"
    # local host_2="127.0.0.1 argo-server.deploykf.example.com"
    # local host_3="127.0.0.1 minio-api.deploykf.example.com"
    # local host_4="127.0.0.1 minio-console.deploykf.example.com"

    # sudo grep -qF "$host_1" /etc/hosts || sudo echo "$host_1" >> /etc/hosts
    # sudo grep -qF "$host_2" /etc/hosts || sudo echo "$host_2" >> /etc/hosts
    # sudo grep -qF "$host_3" /etc/hosts || sudo echo "$host_3" >> /etc/hosts
    # sudo grep -qF "$host_4" /etc/hosts || sudo echo "$host_4" >> /etc/hosts

    printf "exposing deployKF kubernetes application stack... \n"
    kubectl port-forward --namespace "deploykf-istio-gateway" svc/deploykf-gateway 8080:http 8443:https
}

# expose_deployKF