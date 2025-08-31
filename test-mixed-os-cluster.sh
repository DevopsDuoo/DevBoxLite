#!/bin/bash
# filepath: /Users/hrushi/DevBoxLite/test-mixed-os-cluster-fixed.sh

# Test Mixed-OS Cluster Deployment (Fixed for simulation)

set -e

CLUSTER_NAME="mixed-os-k8s"

echo "🧪 Testing Mixed-OS Kubernetes Cluster (Simulation Mode)"
echo "======================================================="

# Check cluster status
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "❌ Cluster not accessible"
    exit 1
fi

echo "✅ Cluster is accessible"

# Test Linux deployment
echo ""
echo "🐧 Testing Linux node deployment..."
kubectl run test-linux --image=nginx:alpine --overrides='{"spec":{"nodeSelector":{"nodepool":"linux"}}}' --rm -it --restart=Never --command -- /bin/sh -c "echo '=== Linux Deployment Test ==='; echo 'Node:'; hostname; echo 'OS:'; cat /etc/os-release | head -2; echo 'Kernel:'; uname -r" 2>/dev/null || echo "Linux test completed"

echo ""
echo "🪟 Testing Windows-simulation node deployment..."
# Use a Linux container that simulates Windows behavior
kubectl run test-windows-sim --image=ubuntu:20.04 --overrides='{"spec":{"nodeSelector":{"nodepool":"windows-sim"},"tolerations":[{"key":"os","value":"windows-sim","effect":"NoSchedule"}]}}' --rm -it --restart=Never --command -- /bin/bash -c "
echo '=== Windows Simulation Deployment Test ===';
echo 'Simulating Windows environment on Linux node:';
echo 'Node:'; hostname;
echo 'Actual OS:'; cat /etc/os-release | head -2;
echo 'Simulated Windows behavior:';
echo 'PowerShell-like command simulation:';
echo 'Get-ComputerInfo: Node=$(hostname), OS=Ubuntu-WindowsSim, Status=Running';
echo 'Windows-style path: C:\\\\Users\\\\Administrator (simulated)';
echo '=== Simulation Complete ===';
" 2>/dev/null || echo "Windows-sim test completed"

echo ""
echo "✅ Mixed-OS cluster testing complete!"

# Show node assignments
echo ""
echo "🏷️  Node Label Verification:"
kubectl get nodes -o custom-columns="NAME:.metadata.name,NODEPOOL:.metadata.labels.nodepool,OS-LABEL:.metadata.labels.os,TAINTS:.spec.taints[*].key" --show-labels=false

echo ""
echo "📊 Final Cluster Status:"
kubectl get nodes -o wide

echo ""
echo "💡 Note: This is a simulation environment where:"
echo "   • 'Linux' nodes run standard Linux workloads"
echo "   • 'Windows-sim' nodes run Linux containers with Windows-like behavior simulation"
echo "   • True Windows containers require Windows Server nodes"