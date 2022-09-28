#!/bin/bash
export K8S_VERSION=1.22 #specify a version
export CP_ADDRESS=10.0.1.10 #make sure this matches your CP node internal address
# Bring node to current versions
sudo apt-get update && sudo apt-get upgrade -y

# Add an alias for the local system to /etc/hosts
sudo sh -c "echo $CP_ADDRESS k8scp >> /etc/hosts"

# Install docker
sudo apt-get install -y docker.io

# Add Kubernetes repo and software 
sudo sh -c "echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' >> /etc/apt/sources.list.d/kubernetes.list"

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

sudo apt-get update


sudo apt-get install -y kubeadm=$K8S_VERSION.1-00 kubelet=$K8S_VERSION.1-00 kubectl=$K8S_VERSION.1-00
sudo apt-mark hold kubeadm kubelet kubectl

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

cat << EOF > kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: $K8S_VERSION.1
controlPlaneEndpoint: "k8scp:6443"
networking:
  podSubnet: 192.168.0.0/16
EOF

# Now install the cp using the kubeadm.yaml file from tarball
sudo kubeadm init --config=kubeadm-config.yaml --upload-certs | tee kubeadm-init.out

sleep 5

echo "Running the steps explained at the end of the init output for you"

mkdir -p $HOME/.kube

sleep 2

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sleep 2

sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "Apply Calico network plugin from ProjectCalico.org"
echo "If you see an error they may have updated the yaml file"
echo "Use a browser, navigate to the site and find the updated file"

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo

#make life easier
sudo apt-get install bash-completion -y
echo "source <(kubectl completion bash)" >> $HOME/.bashrc
source ~/.bashrc

# Add Helm to make our life easier
# wget https://get.helm.sh/helm-v3.7.0-linux-amd64.tar.gz
# tar -xf helm-v3.7.0-linux-amd64.tar.gz
# sudo cp linux-amd64/helm /usr/local/bin/

echo
sleep 3
echo "You should see this node in the output below"
echo "It can take up to a minute for node to show Ready status"
echo
kubectl get node
echo
echo
echo "Script finished. Copy the run_this_on_worker script onto your worker node, make it executable and run it"

cp k8sworker.sh run_this_on_worker.sh
tail kubeadm-init.out -n 2 >> run_this_on_worker.sh

