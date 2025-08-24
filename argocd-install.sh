#!/bin/bash
set -e

VM_NAME="cp-1"

echo "🔐 Entering Multipass shell for $VM_NAME..."
multipass shell $VM_NAME <<'EOF'

echo "📦 Installing ArgoCD components..."

# Create namespace
kubectl create namespace argocd

# Install ArgoCD using official manifests
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "✅ ArgoCD installed in namespace 'argocd'"

# Expose ArgoCD server via NodePort (for local access)
kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "NodePort"}}'

echo "🌐 ArgoCD server exposed via NodePort"

# Print initial admin password
echo "🔑 Initial ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

EOF

echo "🎯 ArgoCD installation complete on $VM_NAME"
