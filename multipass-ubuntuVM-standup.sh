
#launch a multipass kubernetes cluster on ubuntu 24.04 LTS on Apple Silicon

#!/bin/bash
set -e

# ┌────────────────────────────────────────────┐
# │  Launch 7 Multipass VMs for Cluster Rehearsal │
# └────────────────────────────────────────────┘

# Control Plane VMs
for i in 1 2 3; do
  multipass launch --name "cp-$i" \
    --cpus 2 --memory 4G --disk 15G \
    --cloud-init ./ubuntu-k8s-standup.yaml  
  sleep 10
done

# CPU Worker VMs
for i in 1 2; do
  multipass launch --name "cpu-worker-$i" \
    --cpus 1 --memory 2G --disk 15G \
    --cloud-init ./ubuntu-k8s-standup.yaml
  sleep 10
done

# Bastion VMs
for i in 1; do
  multipass launch --name "bastion-$i" \
    --cpus 1 --memory 1G --disk 15G \
    --cloud-init ./ubuntu-k8s-standup.yaml
  sleep 10
done

echo "✅ All VMs launched. Use 'multipass list' to verify status."

  

