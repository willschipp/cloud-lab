#!/bin/bash
# setup nvidia for kubernetes

USER_NAME=${SUDO_USER:-$USER}

# setup ns
kubectl --kubeconfig /home/$USER_NAME/.kube/config create ns gpu-operator
kubectl --kubeconfig /home/$USER_NAME/.kube/config label --overwrite ns gpu-operator pod-security.kubernetes.io/enforce=privileged
# install nvidia helm
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update
helm install --wait --generate-name -n gpu-operator --create-namespace nvidia/gpu-operator

# wait for it to be ready
until kubectl --kubeconfig /home/$USER_NAME/.kube/config get pods -n gpu-operator 2>/dev/null \
  | grep -Ev 'NAME|Completed' \
  | awk '{print $3}' \
  | grep -qvE 'Running|Completed'; do
    kubectl --kubeconfig /home/$USER_NAME/.kube/config get pods -n gpu-operator
    sleep 5
done
