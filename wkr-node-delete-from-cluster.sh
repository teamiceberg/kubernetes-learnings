#!/bin/bash
set -e

# Node name to remove
VM_NAME="$1"

if [ -z "$VM_NAME" ]; then
  echo "Usage: $0 <vm-name>"
  exit 1
fi

echo "You are about to remove node: $VM_NAME"
read -p "Are you sure? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi

VM_IP=$(multipass info "$VM_NAME" --format json | jq -r '.info."'"$VM_NAME"'".ipv4[0]')
CP_NAME="cp-1"
CP_IP=$(multipass info "$CP_NAME" --format json | jq -r '.info."'"$CP_NAME"'".ipv4[0]')

echo "multipass shelling into CP VM:$CP_NAME with IP:${CP_IP}..."

multipass shell $CP_NAME << EOF
  set -euo pipefail

  # Export to KUBECONFIG should be already set. But just in case...
  sudo chmod 644 /etc/kubernetes/admin.conf
  export KUBECONFIG=/etc/kubernetes/admin.conf

  # Check if node exists in API server
  if kubectl get node ${VM_NAME} &>/dev/null; then
 
    echo -e "\nCordoning & Draining Node:${VM_NAME}..."
    kubectl cordon ${VM_NAME}
    kubectl drain ${VM_NAME} --ignore-daemonsets --delete-emptydir-data

    echo -e "\nDeleting Node:${VM_NAME}..."
    kubectl delete node ${VM_NAME}

    echo -e "\nNode:${VM_NAME} successfully removed from K8S cluster and deleted!!!"

  else
    echo -e "\nNode '$VM_NAME' not found in API server. Skipping offboarding.\n"
  fi

EOF