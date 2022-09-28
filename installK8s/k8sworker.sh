#!/bin/bash
export K8S_VERSION=1.22 #specify a version
export CP_ADDRESS=10.0.1.10 #make sure this matches your CP node internal address

sudo apt-get update && sudo apt-get upgrade -y

sudo apt-get install -y vim nano 

# Install docker
sudo apt-get install -y docker.io

# Add Kubernetes repo and software 
sudo sh -c "echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' >> /etc/apt/sources.list.d/kubernetes.list"

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

sudo apt-get update

sudo apt-get install -y kubeadm=$K8S_VERSION.1-00 kubelet=$K8S_VERSION.1-00 kubectl=$K8S_VERSION.1-00

#tell docker to use systemd
sudo tee "/etc/docker/daemon.json" > /dev/null << EOF 
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl restart docker
sleep 5

# Add an alias for the local system to /etc/hosts
sudo sh -c "echo $CP_ADDRESS k8scp >> /etc/hosts"

echo "now running sudo kubeadm init "

sudo 