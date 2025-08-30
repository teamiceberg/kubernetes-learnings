

# ┌────────────────────────────────────────────┐
# │  Safe Delete all VMs and clean up          │
# └────────────────────────────────────────────┘
#!/bin/bash

NUM_CP=3
NUM_CPU_WKR=2
NUM_BAST=1

# Delete Control Plane VMs
for i in $(seq 1 $NUM_CP); do
  multipass delete "cp-$i" --purge
done

# Delete CPU Worker VMs
for i in $(seq 1 $NUM_CPU_WKR); do
  multipass delete "cpu-worker-$i" --purge
done

# Delete Bastion VMs
for i in $(seq 1 $NUM_BAST); do
  multipass delete "bastion-$i" --purge
done

echo "✅ All VMs deleted. "
echo "'multipass list' status: $(multipass list)"

  

