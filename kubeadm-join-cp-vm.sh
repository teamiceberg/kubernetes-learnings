#!/bin/bash
set -e

VM_NAME="cp-3"
POD_CIDR="192.168.0.0/16"
K8S_VERSION="v1.33.4"
VM_IP=$(multipass info "$VM_NAME" --format json | jq -r '.info."'"$VM_NAME"'".ipv4[0]')
CP_IP="192.168.73.14:6443"
TOKEN="ic0a51.kfujk5rugwlhs7ol"
CA_HASH="sha256:bd532fd5423ac1d44d99e782b8c768262a7659f018b681c31a3de2ac0fc60b07"
CERT_KEY="e838dfe639732f16a44256ea8b56bd406b14c21443b075e413604630643f7e2c"

echo "Entering $VM_NAME with IP: $VM_IP to initialize control plane and CNI..."

multipass shell $VM_NAME << EOF
  set -euo pipefail
 
  echo "Starting kubelet and containerd..."

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

  echo -e "\nJoining $VM_NAME control plane node with IP: $VM_IP to cluster..."
  sudo kubeadm join $CP_IP --token $TOKEN --discovery-token-ca-cert-hash $CA_HASH --control-plane --certificate-key $CERT_KEY

  echo -e "\nRestarting services..."
  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl restart kubelet
  sudo systemctl restart containerd

  sudo chmod 644 /etc/kubernetes/admin.conf
  export KUBECONFIG=/etc/kubernetes/admin.conf

  echo -e "\n\n✅ JOIN complete for $VM_NAME."
  
EOF

