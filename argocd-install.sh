#!/bin/bash
set -e

# VM Name to Init
CP_VM="$1"

if [ -z "$CP_VM" ]; then
  echo "Usage: $0 <cp-vm-name>"
  exit 1
fi


echo "Entering Multipass shell for $CP_VM..."
multipass shell $CP_VM <<EOF

  set -euo pipefail

  # Create namespace
  kubectl create namespace argocd

  # Install Argo CD core components
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

  # Expose Argo CD server (NodePort for simplicity)
  kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "targetPort": 8080, "nodePort": 10443}]}}'

  # Get initial admin password
  kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d && echo

  echo -e"\nArgoCD installation complete on $CP_VM"

EOF


