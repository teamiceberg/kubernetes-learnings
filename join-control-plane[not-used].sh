#!/bin/bash

# Step 1: Extract IP of cp-1
CP1_NAME="cp-1"
CP1_IP=$(multipass info "$CP1_NAME" --format json | jq -r ".info.\"$CP1_NAME\".ipv4[0]")

echo -e "\nControl plane IP: $CP1_IP"

# Step 2: Upload certs and extract certificate key

CERT_KEY=$(multipass exec "$CP1_NAME" -- \
  sudo kubeadm init phase upload-certs --upload-certs --v=5 | grep -oE '[a-f0-9]{64}')

echo -e "\nCertificate key: $CERT_KEY"

# Step 3: Generate full join command
JOIN_CMD=$(multipass exec "$CP1_NAME" -- \
    sudo kubeadm token create --print-join-command --certificate-key $CERT_KEY)

echo -e "\nJoin command:"
echo "$JOIN_CMD"

# Step 4: Execute join command inside cp-2 and cp-3

echo -e "\nEnabling IP forwarding in cp-2..."
multipass shell "cp-2" << EOF
    set -euo pipefail 
    sudo sysctl -w net.ipv4.ip_forward=1
    grep -qxF 'net.ipv4.ip_forward = 1' /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
EOF

echo -e "\nJoining $NODE to control plane..."
multipass exec "cp-2" -- sudo $JOIN_CMD --v=5

