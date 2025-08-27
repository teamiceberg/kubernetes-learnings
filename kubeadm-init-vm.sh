#!/bin/bash
set -e

VM_NAME="cp-1"

  ## echo -e "[Service]\nExecStart=\nExecStart=/usr/bin/kubelet --address=127.0.0.1 --authentication-token-webhook=false" | \
    ##sudo tee /etc/systemd/system/kubelet.service.d/10-override.conf &> /dev/null

  ##  echo "Restoring kubelet default configs..."
  # sudo rm /etc/systemd/system/kubelet.service.d/99-override.conf || true

echo -e "\nRecopying certain configs to /tmp folder if they get wiped out when init-vm-prep is run!!!"
[ ! -f /tmp/kubelet-config.yaml ] && multipass transfer /Users/shivamacpro/LearningProjects/alembic-learnings/kubelet-config.yaml $VM_NAME:/tmp/
[ ! -f /tmp/kubeadm-config.yaml ] && multipass transfer /Users/shivamacpro/LearningProjects/alembic-learnings/kubeadm-config.yaml $VM_NAME:/tmp/

echo "Entering $VM_NAME to initialize control plane and CNI..."

multipass shell $VM_NAME << EOF
  set -euo pipefail

  POD_CIDR="192.168.0.0/16"
  K8S_VERSION="v1.33.4"
  VM_NAME="cp-1"

  echo "Starting kubelet and containerd..."
  [ -f /tmp/kubelet-config.yaml ] && sudo cp -f /tmp/kubelet-config.yaml /etc/kubernetes/kubelet-config.yaml
  [ -f /tmp/kubelet-config.yaml ] && sudo chmod 644 /etc/kubernetes/kubelet-config.yaml
  [ -f /tmp/kubeadm-config.yaml ] && sudo cp -f /tmp/kubeadm-config.yaml /etc/kubernetes/kubeadm-config.yaml
  [ -f /tmp/kubeadm-config.yaml ] && sudo chmod 644 /etc/kubernetes/kubeadm-config.yaml
  sudo systemctl start containerd || true
  sudo systemctl start kubelet || true

  echo -e "\nEnabling IP forwarding..."
  sudo sysctl -w net.ipv4.ip_forward=1
  grep -qxF 'net.ipv4.ip_forward = 1' /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
  sudo sysctl -p

  echo -e "\nConfiguring containerd..."
  containerd config default | sudo tee /etc/containerd/config.toml

  echo "Pulling required Kubernetes images with correct sandbox version..."
  sudo kubeadm config images pull --image-repository registry.k8s.io --kubernetes-version=${K8S_VERSION}


  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl restart kubelet

  
  echo "Running kubeadm init for $VM_NAME..."
  sudo kubeadm init --config=/etc/kubernetes/kubeadm-config.yaml --ignore-preflight-errors=all
  sudo chmod 644 /etc/kubernetes/admin.conf

  echo "Setting up kubeconfig for current user..."
  sudo cp -f /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
  sudo chmod 644 /home/ubuntu/.kube/config

  echo -e "\nInitiating Calico CNI..."
  sudo kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml --validate=false

  echo -e"\n✅ Init complete for $VM_NAME. Control plane and Calico-ready networking are now live.\n "
  
EOF

