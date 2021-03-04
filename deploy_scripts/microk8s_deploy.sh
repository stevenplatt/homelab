#!/bin/sh
# this script is most recently tested with Ubuntu Server 20.04 LTS
# script is a modification of instructions provided by https://kdjlab.com/microk8s-installation/

# script functions ###################################################################################

function install_microk8s(){
    sudo snap install microk8s --classic
    sudo usermod -a -G microk8s $USER # add current user to microk8s group
    sudo chown -f -R $USER ~/.kube # changes ownership to current user
    su - $USER # enter super user mode for changing bash alias in next step
}

function add_alias(){
    # adds bash alias so that we can use command "kubectl" instead of "microk8s kubectl"
    echo "alias kubectl='microk8s kubectl'" > .bash_aliases
    source .bash_aliases
}

function check_initialized(){
    # check and wait for newly installed Kubernetes instance to initialize
    # future check will be added here, for now, script simply sleeps while microk8s starts
    printf "Initializing Microk8s Cluster..."
    sleep 3m # pause script for 3 minutes while microk8s initializes
}

function install_addons(){
    # enable additional services for microk8s basic functionality
    microk8s enable ingress 
    microk8s enable dns 
    microk8s enable storage 
    microk8s enable prometheus # monitoring
    microk8s enable dashboard # web ui
}

function get_token(){
    echo "\n\n\n\n\n"

    # print the access token required to log into the web ui
    token=$(kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)
    kubectl -n kube-system describe secret $token

    echo "\n\n\n\n\n"
}

function forward_webui(){
    # forward kubernetes web ui at port 443 to the virtual machine IP at port 10443 for outside access
    # "microk8s kubectl" format is required for the command, nohup command seems to ignore the kubectl bash alias
    nohup microk8s kubectl port-forward -n kube-system service/kubernetes-dashboard --address=0.0.0.0 10443:443 &>/dev/null & disown
    echo "\n"
    echo "Kubernetes is online and can be accessed at https://[server_ip]:10443"
    echo "The above token output will be required when accessing the web ui"
    echo "\n\n\n\n\n"
}

# script running logic ###############################################################################

install_microk8s
add_alias
check_initialized
install_addons
get_token
forward_webui

# copy and paste the token that is printed. 
# this token is used to log into the web ui.