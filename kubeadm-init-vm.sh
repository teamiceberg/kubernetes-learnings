#!/bin/bash
set -e

VM_NAME="cp-1"
POD_CIDR="192.168.0.0/16"
K8S_VERSION="v1.33.4"
VM_IP=$(multipass info "$VM_NAME" --format json | jq -r '.info."'"$VM_NAME"'".ipv4[0]')
ETCD_PORT="2379"

echo -e "\nRecopying certain configs to /tmp folder ifshould they get wiped out when init-vm-prep is run!!!"
multipass transfer /Users/shivamacpro/LearningProjects/alembic-learnings/kubelet-config.yaml $VM_NAME:/tmp/
multipass transfer /Users/shivamacpro/LearningProjects/alembic-learnings/kubeadm-config.yaml $VM_NAME:/tmp/
multipass transfer /Users/shivamacpro/LearningProjects/alembic-learnings/crictl.yaml $VM_NAME:/tmp/


echo "Entering $VM_NAME to initialize control plane and CNI..."

multipass shell $VM_NAME << EOF
  set -euo pipefail
 
  echo "Starting kubelet and containerd..."
  [ -f /tmp/kubelet-config.yaml ] && sudo cp -f /tmp/kubelet-config.yaml /etc/kubernetes/kubelet-config.yaml
  [ -f /tmp/kubelet-config.yaml ] && sudo chmod 644 /etc/kubernetes/kubelet-config.yaml
  [ -f /tmp/kubeadm-config.yaml ] && sudo cp -f /tmp/kubeadm-config.yaml /etc/kubernetes/kubeadm-config.yaml
  [ -f /tmp/kubeadm-config.yaml ] && sudo chmod 644 /etc/kubernetes/kubeadm-config.yaml
  [ -f /tmp/crictl.yaml ] && sudo cp -f /tmp/crictl.yaml /etc/crictl.yaml
  [ -f /tmp/crictl.yaml ] && sudo chmod 644 /etc/crictl.yaml

  sudo systemctl restart containerd || true
  sudo systemctl restart kubelet || true

  echo -e "\nRe-Enabling IP forwarding..."
  sudo sysctl -w net.ipv4.ip_forward=1
  grep -qxF 'net.ipv4.ip_forward = 1' /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
  sudo sysctl -p

  echo -e "\nRe-Configuring containerd..."
  sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
  sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
  sudo sed -i 's/systemd_cgroup = true/systemd_cgroup = false/g' /etc/containerd/config.toml
  sudo sed -i 's|pause:3\.8|pause:3.10|g' /etc/containerd/config.toml

  echo -e "\nAssigning the correct VM IP to various kubeadm-config flags..."
  sudo sed -i 's/^ *advertiseAddress:.*$/  advertiseAddress: ${VM_IP}/' /etc/kubernetes/kubeadm-config.yaml
  sudo sed -i "s/^controlPlaneEndpoint:.*$/controlPlaneEndpoint: \"${VM_IP}:6443\"/" /etc/kubernetes/kubeadm-config.yaml
  sudo sed -i "s/^ *node-ip:.*$/    node-ip: \"${VM_IP}\"/"  /etc/kubernetes/kubeadm-config.yaml


  echo -e "\nRestarting services..."
  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl restart kubelet
  sudo systemctl restart containerd

  echo -e "\nRunning 'kubeadm init' up to kubeconfig admin phase for $VM_NAME..."
  
  sudo kubeadm init phase certs all --config=/etc/kubernetes/kubeadm-config.yaml --v=5
  sudo kubeadm init phase kubeconfig all --config=/etc/kubernetes/kubeadm-config.yaml  --v=5
  sudo chmod 644 /etc/kubernetes/admin.conf
  export KUBECONFIG=/etc/kubernetes/admin.conf

  echo "Setting up kubeconfig for current user..."
  sudo mkdir -p /home/ubuntu/.kube
  sudo cp -f /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
  sudo chmod 644 /home/ubuntu/.kube/config

  echo -e "\nRunning kubeadm init fully for $VM_NAME..."
  sudo kubeadm init --config /etc/kubernetes/kubeadm-config.yaml

  echo -e "\nRunning kubeadm init phase upload-certs..."
  sudo chmod 644 /etc/kubernetes/*.conf
  sudo chmod 644 /etc/kubernetes/pki/*.*
  sudo chmod 644 /etc/kubernetes/pki/etcd/*.*
  sudo kubeadm init phase upload-certs --upload-certs --v=5 | grep -oE '[a-f0-9]{64}' | sudo tee /root/cert-key.key

  echo -e "\nKubeadm init done. Initiating Calico CNI and Tigera operator for pod network..."
  kubectl apply --server-side -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/tigera-operator.yaml
  kubectl apply --server-side -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/operator-crds.yaml
  kubectl apply --server-side -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/custom-resources.yaml



  echo -e "\nChecking etcd database health...\n"
  sudo etcdctl \
  --endpoints=${VM_IP}:${ETCD_PORT} \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  endpoint health

  echo -e "\n\n✅ Init complete for $VM_NAME. Control plane and Calico-ready networking are now live."

  
EOF

