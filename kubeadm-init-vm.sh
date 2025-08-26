#!/bin/bash
set -e

VM_NAME="cp-1"


echo "Entering $VM_NAME to initialize control plane and CNI..."

multipass shell $VM_NAME << EOF
  set -euo pipefail

  POD_CIDR="192.168.0.0/16"
  K8S_VERSION="v1.33.4"
  VM_NAME="cp-1"

  echo "Starting kubelet and containerd..."
  sudo systemctl start containerd || true
  sudo systemctl start kubelet || true

  echo -e "\nConfiguring containerd..."
  sudo mkdir -p /etc/containerd
  containerd config default | sudo tee /etc/containerd/config.toml

  echo "Enabling IP forwarding..."
  sudo sysctl -w net.ipv4.ip_forward=1
  echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
  sudo sysctl -p

  echo "Pulling required Kubernetes images with correct sandbox version..."
  sudo kubeadm config images pull --image-repository registry.k8s.io --kubernetes-version=${K8S_VERSION}

  echo "Restoring kubelet default port binding..."
  sudo rm /etc/systemd/system/kubelet.service.d/99-override.conf || true

  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl restart kubelet


  echo -e "\nSetting up .kube directory..."
  sudo mkdir -p /home/ubuntu/.kube
  
  echo "Running kubeadm init for $VM_NAME..."
  sudo kubeadm init --kubernetes-version=${K8S_VERSION} --image-repository registry.k8s.io --pod-network-cidr=${POD_CIDR} --ignore-preflight-errors=all --v=5
  echo -e "\nInitiating Calico CNI..."
  sudo kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
  sudo chmod 644 /etc/kubernetes/admin.conf

  echo "Setting up kubeconfig for current user..."
  sudo cp -f /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
  sudo chmod 644 /home/ubuntu/.kube/config

  echo -e"\n✅ Init complete for $VM_NAME. Control plane and Calico-ready networking are now live.\n "
  
EOF

