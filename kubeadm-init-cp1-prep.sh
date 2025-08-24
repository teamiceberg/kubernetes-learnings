#!/bin/bash
set -e

VM_NAME="cp-1"

echo "Entering $VM_NAME to apply kubeadm init prep..."
multipass shell $VM_NAME <<'EOF'
  set -euo pipefail
 
  echo "Resetting kubeadm and stopping services..."
  sudo kubeadm reset -f || true
  sudo systemctl stop kubelet || true
  sudo systemctl stop containerd || true
  sudo pkill -f kubelet || true

  echo "Cleaning residual kubelet and CNI state..."
  sudo rm -rf /etc/cni/net.d
  sudo rm -rf /var/lib/cni/
  sudo rm -rf /var/lib/kubelet/*
  sudo rm -rf /etc/kubernetes

  sudo ip link delete cni0 || true
  sudo ip link delete tunl0 || true

  echo "Muting kubelet port 10250..."
  sudo mkdir -p /etc/systemd/system/kubelet.service.d
  echo -e "[Service]\nExecStart=\nExecStart=/usr/bin/kubelet --address=127.0.0.1 --port=0" | \
    sudo tee /etc/systemd/system/kubelet.service.d/override.conf

  echo "Reloading systemd..."
  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload

  echo "🔧 Starting kubelet and containerd..."
  sudo systemctl restart containerd || true
  sudo systemctl restart kubelet || true

  echo "✅ Init prep applied. Ready for kubeadm init."
 
EOF

