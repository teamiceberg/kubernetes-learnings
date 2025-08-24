#!/bin/bash
set -e

VM_NAME="cp-1"

echo "Entering $VM_NAME to initialize control plane..."

multipass shell $VM_NAME <<'EOF'
  set -euo pipefail
  POD_CIDR="192.168.0.0/16"
  K8S_VERSION="v1.33.4"

  echo "Enabling IP forwarding..."
  sudo sysctl -w net.ipv4.ip_forward=1
  echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
  sudo sysctl -p

  echo "Pulling required Kubernetes images with correct sandbox version..."
  sudo kubeadm config images pull --image-repository registry.k8s.io --kubernetes-version=${K8S_VERSION}

  echo "Restoring kubelet default port binding..."
  sudo rm /etc/systemd/system/kubelet.service.d/override.conf || true

  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl restart kubelet

  echo "Restarting and configuring containerd..."
  sudo systemctl restart containerd
  sudo mkdir -p /etc/containerd
  containerd config default | sudo tee /etc/containerd/config.toml
  
  echo "Running kubeadm init for CP1. Initiating Calico CNI..."
  sudo kubeadm init --kubernetes-version=${K8S_VERSION} --image-repository registry.k8s.io --pod-network-cidr=${POD_CIDR}

  echo "Setting up kubeconfig for current user..."
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  echo "✅ Init complete. Control plane and Calico-ready networking are now live. "
  
EOF

