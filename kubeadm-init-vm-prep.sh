#!/bin/bash
set -e

VM_NAME="cp-1"

echo "Recopying kubelet-config to /etc folder as it gets wiped out in the kubeadm reset"
multipass exec $VM_NAME -- mkdir -p /home/ubuntu/etc
multipass transfer /Users/shivamacpro/LearningProjects/alembic-learnings/kubelet-config.yaml $VM_NAME:/home/ubuntu/etc/kubelet-config.yaml

echo "Entering $VM_NAME to apply kubeadm init prep..."
multipass shell $VM_NAME <<EOF
  set -euo pipefail

  VM_NAME="cp-1"
 
  echo "Stopping services..."
  sudo systemctl stop kubelet || true
  sudo systemctl stop containerd || true
  sudo pkill -f kubelet || true
  sudo pkill -f containerd || true

  echo -e "\nRemoving manifests..."
  sudo rm -rf /etc/kubernetes/manifests
  sudo rm -rf ~/.kube

  echo -e "\nMuting kubelet port 10250..."
  sudo mkdir -p /etc/systemd/system/kubelet.service.d
  echo -e "[Service]\nExecStart=\nExecStart=/usr/bin/kubelet --address=127.0.0.1 --read-only-port=0" | \
    sudo tee /etc/systemd/system/kubelet.service.d/99-override.conf &> /dev/null

  echo -e "\nReloading systemd..."
  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload

  echo -e "\n✅ Init prep applied to $VM_NAME. Ready for kubeadm init.\n"
 
EOF

