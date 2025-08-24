
#launch a multipass kubernetes cluster on ubuntu 24.04 LTS on Apple Silicon

# ┌────────────────────────────────────────────┐
# │  Launch 7 Multipass VMs for Cluster Rehearsal │
# └────────────────────────────────────────────┘
#!/bin/bash

# Delete Control Plane VMs
for i in 1 2 3; do
  multipass delete "cp-$i" --purge
done

# Delete CPU Worker VMs
for i in 1 2; do
  multipass delete "cpu-worker-$i" --purge
done

# Delete GPU Worker VMs (simulated)
for i in 1 2; do
  multipass delete "gpu-worker-$i" --purge
done

echo "✅ All VMs deleted. "
echo "'multipass list' status: $(multipass list)"

  

