#!/bin/bash
set -e

# Worker VM Name to Join
VM_NAME="$1"

if [ -z "$VM_NAME" ]; then
  echo "Usage: $0 <vm-name>"
  exit 1
fi

POD_CIDR="192.168.0.0/16"
K8S_VERSION="v1.33.4"
VM_IP=$(multipass info "$VM_NAME" --format json | jq -r '.info."'"$VM_NAME"'".ipv4[0]')
CP_IP="192.168.74.26"
CP_PORT="6443"
ETCD_PORT="2379"
TOKEN="cn19bc.c55exntffn3zjstk"
CA_HASH="sha256:b699ba95433ed2271dae78fc02734e85b54277071d38f77b6c2e80dc030c3925"
CERT_KEY="e20ef75eeb12c624083c8fc8eb06cb65634f4c7ace03f03d8480e961be3bd60f"

echo -e "\nJoining ${VM_NAME} with IP: $VM_IP to control plane..."

echo -e "\nmultipass shelling into $VM_NAME "

multipass shell $VM_NAME << EOF
  set -euo pipefail

  echo -e "\nRemoving any pre-exisiting confs and manifests..."
  sudo rm -rf /etc/kubernetes/* /var/lib/kubelet/* /var/lib/etcd/*
 
  echo -e "\nStarting kubelet and containerd..."
  sudo systemctl restart containerd || true
  sudo systemctl restart kubelet || true

  echo -e "\nEnabling IP forwarding..."
  sudo sysctl -w net.ipv4.ip_forward=1
  grep -qxF 'net.ipv4.ip_forward = 1' /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
  sudo sysctl -p

  echo -e "\nRe-Configuring containerd..."
  sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
  sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
  sudo sed -i 's/systemd_cgroup = true/systemd_cgroup = false/g' /etc/containerd/config.toml
  sudo sed -i 's|pause:3\.8|pause:3.10|g' /etc/containerd/config.toml


  echo -e "\nJoining $VM_NAME control plane node with IP: $VM_IP to cluster..."
  sudo kubeadm join ${CP_IP}:${CP_PORT} --token $TOKEN --discovery-token-ca-cert-hash $CA_HASH

  echo -e "\nRestarting services..."
  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl restart kubelet
  sudo systemctl restart containerd

  echo -e "\n\n✅ JOIN complete for $VM_NAME."
  
EOF

