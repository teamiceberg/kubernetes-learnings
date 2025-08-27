#!/bin/bash

##  echo -e "\nMuting kubelet port 10250..."
  #echo -e "[Service]\nExecStart=\nExecStart=/usr/bin/kubelet --config=/home/ubuntu/etc/kubernetes/kubelet-config.yaml" | \
    #sudo tee /etc/systemd/system/kubelet.service.d/99-override.conf &> /dev/null


set -e

VM_NAME="cp-1"

echo -e "\nEntering $VM_NAME to apply kubeadm init prep..."
multipass shell $VM_NAME <<EOF
  set -euo pipefail

  VM_NAME="cp-1"
 
  echo -e "\nStopping services..."
  sudo systemctl stop kubelet || true
  sudo systemctl stop containerd || true
  sudo pkill -f kubelet || true
  sudo pkill -f containerd || true

  echo -e "\nRemoving confs and manifests..."
  sudo rm -rf /etc/kubernetes/*
  sudo rm -rf ~/.kube/*

  echo -e "\nReloading systemd..."
  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload

  echo -e "\n✅ Init prep applied to $VM_NAME. Ready for kubeadm init.\n"
 
EOF

