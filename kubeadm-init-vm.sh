#!/bin/bash
set -e

VM_NAME="cp-1"
POD_CIDR="192.168.0.0/16"
K8S_VERSION="v1.33.4"
VM_IP=$(multipass info "$VM_NAME" --format json | jq -r '.info."'"$VM_NAME"'".ipv4[0]')

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

  echo -e "\nEnabling IP forwarding..."
  sudo sysctl -w net.ipv4.ip_forward=1
  grep -qxF 'net.ipv4.ip_forward = 1' /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
  sudo sysctl -p

  echo -e "\nRe-Configuring containerd..."
  sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
  sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
  sudo sed -i 's/systemd_cgroup = true/systemd_cgroup = false/g' /etc/containerd/config.toml

  echo -e "\nAssigning the correct VM IP to kubeadm-config..."
  sudo sed -i 's/^ *advertiseAddress:.*$/  advertiseAddress: ${VM_IP}/' /etc/kubernetes/kubeadm-config.yaml
  


  echo -e "\nRestarting services..."
  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl restart kubelet
  sudo systemctl restart containerd
  
  echo -e "\nRunning 'kubeadm init' PHASEWISE for $VM_NAME..."

  echo -e "\nRunning 'kubeadm init' up to kubeconfig admin phase..."
  
  sudo kubeadm init phase certs all --config=/etc/kubernetes/kubeadm-config.yaml --v=5
  sudo kubeadm init phase kubeconfig admin --config=/etc/kubernetes/kubeadm-config.yaml  --v=5
  sudo chmod 644 /etc/kubernetes/admin.conf
  export KUBECONFIG=/etc/kubernetes/admin.conf

  echo "Setting up kubeconfig for current user..."
  sudo mkdir -p /home/ubuntu/.kube
  sudo cp -f /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
  sudo chmod 644 /home/ubuntu/.kube/config

  echo -e "\nRunning kubeadm init remaining phases..."
  
  echo -e "\nRunning phase kubeconfig all..."
  sudo kubeadm init phase kubeconfig all --config=/etc/kubernetes/kubeadm-config.yaml --v=5
  echo -e "\nRunning phase control-plane all..."
  sudo kubeadm init phase control-plane all --config=/etc/kubernetes/kubeadm-config.yaml --v=5
  echo -e "\nRunning phase etcd local..."
  sudo kubeadm init phase etcd local --config=/etc/kubernetes/kubeadm-config.yaml --v=5
  echo -e "\nRunning phase kubelet-start..."
  sudo kubeadm init phase kubelet-start --config=/etc/kubernetes/kubeadm-config.yaml --v=5
  echo -e "\nRunning phase mark-control-plane..."
  sudo kubeadm init phase mark-control-plane --config=/etc/kubernetes/kubeadm-config.yaml --v=5
  echo -e "\nRunning phase addon all..."
  sudo kubeadm init phase addon all --config=/etc/kubernetes/kubeadm-config.yaml --v=5
  echo -e "\nRunning phase bootstrap-token..."
  sudo kubeadm init phase bootstrap-token --config=/etc/kubernetes/kubeadm-config.yaml --v=5


  echo -e "\nKubeadm init all phases done. Initiating Calico CNI..."
  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

  echo -e "\n\n✅ Init complete for $VM_NAME. Control plane and Calico-ready networking are now live.\n "
  
EOF

