#!/bin/bash
set -e

echo "🧹 Resetting Kubernetes and Calico state..."

# Reset kubeadm and stop services
sudo kubeadm reset -f
sudo systemctl stop kubelet
sudo systemctl stop containerd

# Remove CNI and kubelet residuals
sudo rm -rf /etc/cni/net.d
sudo rm -rf /var/lib/cni/
sudo rm -rf /var/lib/kubelet/*
sudo rm -rf /etc/kubernetes

# Remove Calico-specific interfaces
sudo ip link delete cni0 || true
sudo ip link delete tunl0 || true

# Restart services
sudo systemctl start containerd
sudo systemctl start kubelet

echo "✅ Cleanup complete. Node is ready for re-init."
