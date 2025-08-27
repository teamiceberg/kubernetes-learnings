

# ┌────────────────────────────────────────────┐
# │  Safe Delete all VMs and clean up          │
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

  

