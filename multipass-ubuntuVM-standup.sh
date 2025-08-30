
#launch a multipass kubernetes cluster on ubuntu 24.04 LTS on Apple Silicon

#!/bin/bash
set -e

NUM_CP=3
NUM_CPU_WKR=2
NUM_BAST=1

# ┌────────────────────────────────────────────┐
# │  Launch 7 Multipass VMs for Cluster Rehearsal │
# └────────────────────────────────────────────┘

# Control Plane VMs
for i in $(seq 1 $NUM_CP); do
  multipass launch --name "cp-$i" \
    --cpus 2 --memory 4G --disk 15G \
    --cloud-init ./ubuntu-k8s-standup.yaml  
  sleep 10
done

# CPU Worker VMs
for i in $(seq 1 $NUM_CPU_WKR); do
  multipass launch --name "cpu-worker-$i" \
    --cpus 1 --memory 2G --disk 15G \
    --cloud-init ./ubuntu-k8s-standup.yaml
  sleep 10
done

# Bastion VMs
for i in $(seq 1 $NUM_BAST); do
  multipass launch --name "bastion-$i" \
    --cpus 1 --memory 1G --disk 15G \
    --cloud-init ./ubuntu-k8s-standup.yaml
  sleep 10
done

echo "✅ All VMs launched. Use 'multipass list' to verify status."

  

