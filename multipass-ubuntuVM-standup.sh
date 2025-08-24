
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
    --cpus 2 --memory 4G --disk 15G \
    --cloud-init ./ubuntu-k8s-standup.yaml
  sleep 10
done

# GPU Worker VMs (simulated)
for i in 1 2; do
  multipass launch --name "gpu-worker-$i" \
    --cpus 4 --memory 8G --disk 20G \
    --cloud-init ./ubuntu-k8s-standup.yaml
  sleep 10
done

echo "✅ All VMs launched. Use 'multipass list' to verify status."

  

