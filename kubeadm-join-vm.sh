#!/bin/bash
set -e

# Control Plane VM Name to Join
MODE="$1"
VM_NAME="$2"

if [ -z "$VM_NAME" ] || [ -z "$MODE" ]; then
  echo "Usage: $0 <mode(control-plane|worker)> <vm-name>"
  exit 1
fi

POD_CIDR="192.168.0.0/16"
K8S_VERSION="v1.33.4"
VM_IP=$(multipass info "$VM_NAME" --format json | jq -r '.info."'"$VM_NAME"'".ipv4[0]')
CP_IP="192.168.74.32"
CP_PORT="6443"
ETCD_PORT="2379"
TOKEN="k8g0is.yxqez47d81b0rc67"
CA_HASH="sha256:f2941eb4f97573ce308362f82ab103815863fa8aa1a23731a5bd92c87cb92512"
CERT_KEY="a3bd3b2eacc8e8a7a9f19b441871fd813207b9a55bfdc31a767dc467b9f5303a"

if [ "$MODE" == "control-plane" ]; then
  echo -e "\nJoining ${VM_NAME} with IP: $VM_IP to control plane..."

  echo -e "\nmultipass shelling into $VM_NAME "

  multipass shell $VM_NAME <<EOF
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
    sudo sed -i 's|pause:3\.8|pause:3.10|g' /etc/containerd/config.toml

    echo -e "\nJoining $VM_NAME control plane node with IP: $VM_IP to cluster..."
    sudo kubeadm join ${CP_IP}:${CP_PORT} --token $TOKEN --discovery-token-ca-cert-hash $CA_HASH --control-plane --certificate-key $CERT_KEY

    echo -e "\nRestarting services..."
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet
    sudo systemctl restart containerd

    sudo chmod 644 /etc/kubernetes/admin.conf
    export KUBECONFIG=/etc/kubernetes/admin.conf

    echo -e "\nChecking etcd database health...\n"
    sudo etcdctl \
    --endpoints=${VM_IP}:${ETCD_PORT} \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
    --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
    endpoint health | sudo tee /root/etcd-endpoint-healthstatus.txt

    echo -e "\n\n✅ JOIN complete for $VM_NAME."
EOF
  exit 0
fi

if [ "$MODE" == "worker" ]; then
  
  echo -e "\nRegistering worker node ${VM_NAME} with IP: $VM_IP with control plane..."

  echo -e "\nmultipass shelling into $VM_NAME "

  multipass shell $VM_NAME <<EOF
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


    echo -e "\nAdding worker node $VM_NAME to cluster..."
    sudo kubeadm join ${CP_IP}:${CP_PORT} --token $TOKEN --discovery-token-ca-cert-hash $CA_HASH

    echo -e "\nRestarting services..."
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet
    sudo systemctl restart containerd

    echo -e "\n\n✅ ADDITION complete!!!"
EOF
  exit 0
fi