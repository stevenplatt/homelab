# install ubuntu charmed kubeflow
# script should not be run with sudo

# source: https://charmed-kubeflow.io/docs/get-started-with-charmed-kubeflow

########################
# Install microk8s
########################

install_microk8s(){
    sudo snap install microk8s --classic --channel=1.26/stable
}

set_permissions(){
    sudo usermod -a -G microk8s $USER
    newgrp microk8s # needs to be run each time a new shell is opened
    sudo chown -f -R $USER ~/.kube
}

isntall_microk8s_addons(){
    microk8s enable dns hostpath-storage ingress metallb:10.64.140.43-10.64.140.49 rbac
}

########################
# Install Juju
########################

install_juju(){
    sudo snap install juju --classic --channel=3.1/stable
    mkdir -p ~/.local/share

    # add juju controller to microk8s cluster
    microk8s config | juju add-k8s my-k8s --client
    juju bootstrap my-k8s uk8sx

    # add kubeflow model to juju controller
    juju add-model kubeflow
}

check_and_append_sysctl() {
  # Lines to check
  local line1="fs.inotify.max_user_instances=1280"
  local line2="fs.inotify.max_user_watches=655360"

  sudo grep -qF "$line1" /etc/sysctl.conf || echo "$line1" >> /etc/sysctl.conf
  sudo grep -qF "$line2" /etc/sysctl.conf || echo "$line2" >> /etc/sysctl.conf
}

########################
# Install Kubeflow
########################

install_charmed_kubeflow(){
    # use 'juju status' to verify state of deployment
    juju deploy kubeflow --trust  --channel=1.8/stable
}

configure_kubeflow_dashboard() {
    # Get the IP address using kubectl
    local ip_address=$(sudo -E microk8s kubectl -n kubeflow get svc istio-ingressgateway-workload -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

    # Check if IP address is retrieved successfully
    if [[ -z "$ip_address" ]]; then
        echo "Failed to retrieve IP address for istio-ingressgateway-workload"
        return 1
    fi

    # Configure dex-auth and oidc-gatekeeper with the IP
    juju config dex-auth public-url=http://"$ip_address".nip.io
    juju config oidc-gatekeeper public-url=http://"$ip_address".nip.io

    # COnfigure dex-auth user
    juju config dex-auth static-username=admin
    juju config dex-auth static-password=admin
}
