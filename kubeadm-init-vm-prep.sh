#!/bin/bash
set -e

# VM Name to Init Prep
VM_NAME="$1"

if [ -z "$VM_NAME" ]; then
  echo "Usage: $0 <vm-name>"
  exit 1
fi

echo -e "\nEntering $VM_NAME to apply kubeadm init prep..."
multipass shell $VM_NAME <<EOF
  set -euo pipefail

  echo -e "\nResetting kubeadm first..."
  sudo kubeadm reset --force
  sudo systemctl daemon-reload
  sudo systemctl restart containerd

  echo -e "\nRemoving iptables, confs and manifests..."
  sudo rm -rf /etc/kubernetes/* /var/lib/kubelet/* /var/lib/etcd/*
  sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X

  echo -e "\nReloading systemd..."
  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload


  echo -e "\n✅ Init prep applied to $VM_NAME. Ready for kubeadm init.\n"
 
EOF

