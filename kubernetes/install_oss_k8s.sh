#!/bin/bash

# set versions
CONTAINERD_VERSION="2.1.4"
RUNC_VERSION="1.3.0"
CNI_VERSION="1.3.0"
HELM_VERSION="3.17.4"
K8S_VERSION="1.33"
CALICO_VERSION="3.30.2"
USER_NAME=${SUDO_USER:-$USER}
CERT_MGR_VERSION="1.18.2"

# swapoff
swapoff -a
# network
modprobe br_netfilter
echo '1' > /proc/sys/net/ipv4/ip_forward

#containerd --> docker runner
wget "https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz" # latest version
tar Czxvf /usr/local "containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz"

wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
mv containerd.service /lib/systemd/system/.
systemctl daemon-reload
systemctl enable --now containerd

wget "https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64"
install -m 755 runc.amd64 /usr/local/sbin/runc

# container networking
wget "https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-amd64-v${CNI_VERSION}.tgz"
mkdir -p /opt/cni/bin
tar Czxvf /opt/cni/bin "cni-plugins-linux-amd64-v${CNI_VERSION}.tgz"

#get helm
wget "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz"
tar xzf "helm-v${HELM_VERSION}-linux-amd64.tar.gz"
mv linux-amd64/helm /usr/local/bin/.

#install kdeadm
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key" | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

#move the file
containerd config default > config.toml
sed -i s'/            SystemdCgroup = false/            SystemdCgroup = true/' ./config.toml
mkdir -p /etc/containerd 
mv config.toml /etc/containerd/.
sed -i 's/ExecStart=\/usr\/local\/bin\/containerd/ExecStart=\/usr\/local\/bin\/containerd --config \/etc\/containerd\/config.toml/g' /usr/lib/systemd/system/containerd.service

#continue
systemctl daemon-reload 
systemctl restart containerd 
systemctl enable --now kubelet 
kubeadm init --pod-network-cidr=192.168.0.0/16

# setup kubeconfig
mkdir -p /home/$USER_NAME/.kube && sudo cp -i /etc/kubernetes/admin.conf /home/$USER_NAME/.kube/config && sudo chown $USER_NAME:$USER_NAME /home/$USER_NAME/.kube/config

#calico networking setup
# kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/tigera-operator.yaml
kubectl --kubeconfig /home/$USER_NAME/.kube/config create -f "https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/operator-crds.yaml"
kubectl --kubeconfig /home/$USER_NAME/.kube/config create -f "https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/tigera-operator.yaml"
kubectl --kubeconfig /home/$USER_NAME/.kube/config create -f "https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/custom-resources.yaml"

# check calico pods status automatically
echo "Waiting for all Calico pods to be ready in namespace calico-system..."

until kubectl --kubeconfig /home/$USER_NAME/.kube/config get pods -n calico-system 2>/dev/null \
  | grep -Ev 'NAME|Completed' \
  | awk '{print $3}' \
  | grep -qvE 'Running|Completed'; do
    kubectl --kubeconfig /home/$USER_NAME/.kube/config get pods -n calico-system
    sleep 5
done

echo "All Calico pods are now running."

# install istio
curl -L https://istio.io/downloadIstio | sh -

# move the binary
for dir in ./istio-*; do
  # Check if this is a directory and istioctl exists within it
  if [ -d "$dir" ] && [ -f "$dir/bin/istioctl" ]; then
    echo "Moving $dir/bin/istioctl to /usr/local/bin/"
    sudo mv "$dir/bin/istioctl" /usr/local/bin/
  else
    echo "No istioctl binary in $dir"
  fi
done

# add the istio setup
kubectl --kubeconfig /home/$USER_NAME/.kube/config apply -f ./yamls/ingress.yml

# finish istio
kubectl --kubeconfig /home/$USER_NAME/.kube/config taint nodes --all node-role.kubernetes.io/control-plane-
kubectl --kubeconfig /home/$USER_NAME/.kube/config apply -f ./yamls/istio_ns.yaml
istioctl manifest apply -f ./yamls/istio_operator.yaml -y

# cert manager
kubectl --kubeconfig /home/$USER_NAME/.kube/config apply -f "https://github.com/cert-manager/cert-manager/releases/download/v${CERT_MGR_VERSION}/cert-manager.yaml"

#deploy test container
kubectl --kubeconfig /home/$USER_NAME/.kube/config run test-container --image=nginx --restart=Never --port=80
kubectl --kubeconfig /home/$USER_NAME/.kube/config expose pod test-container --type=NodePort --port=80
kubectl --kubeconfig /home/$USER_NAME/.kube/config get svc test-container