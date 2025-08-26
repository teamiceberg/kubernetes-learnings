#!/bin/bash
set -e

VM_NAME="cp-1"

echo "Entering $VM_NAME to reset kubeadm ..."
multipass shell $VM_NAME << EOF
  set -euo pipefail

  VM_NAME="cp-1"

  echo -e "\nStopping services..."
  sudo systemctl stop kubelet || true
  sudo systemctl stop containerd || true
  sudo pkill -f kubelet || true
  sudo pkill -f containerd || true

  echo -e "\nResetting kubeadm..."
  sudo kubeadm reset -f &> /dev/null  || true

  echo -e "\nCleaning residual kubelet and CNI state..."
  sudo rm -rf /etc/cni/net.d
  sudo rm -rf /var/lib/cni/
  sudo rm -rf /var/lib/kubelet/*
  sudo rm -rf /etc/kubernetes
  sudo ip link delete tunl0 || true

  echo -e "\n✅kubeadm init reset for $VM_NAME and artifacts removed.\n"

  sudo reboot
 
EOF

