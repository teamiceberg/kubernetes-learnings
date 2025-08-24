#!/usr/bin/env bash
set -e


# Your public key
PUBKEY=$(<~/.ssh/multipass_vm_access.pub)

# List of VM names
vms=("cp-1" "cp-2" "cp-3" "cpu-worker-1" "cpu-worker-2" "gpu-worker-1" "gpu-worker-2")

for vm in "${vms[@]}"; do
  echo "🔧Establishing SSH ingress for $vm..."

  multipass exec "$vm" -- bash -c "
    sudo mkdir -p /home/ubuntu/.ssh &&
    echo '$PUBKEY' | sudo tee -a  /home/ubuntu/.ssh/authorized_keys &&
    sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys &&
    sudo chmod 600 /home/ubuntu/.ssh/authorized_keys &&
    sudo apt update -y &&
    sudo apt install -y openssh-server &&
    sudo systemctl enable ssh &&
    sudo systemctl restart ssh &&
    sudo ufw allow ssh
  "
done

echo "✅ SSH ingress established across all VMs."
