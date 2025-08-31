#!/bin/bash
# filepath: /Users/hrushi/DevBoxLite/deploy-mixed-os-simple.sh

# Simple Mixed-OS Kubernetes Cluster Deployment
# Only creates the cluster with Linux and Windows-simulation nodes

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CLUSTER_NAME="mixed-os-k8s"

print_step() {
    echo -e "${BLUE}🔹 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_prerequisites() {
    echo -e "${BLUE}📋 Checking Prerequisites${NC}"
    
    # Check Docker
    if ! docker --version >/dev/null 2>&1; then
        print_error "Docker is not installed or not running"
        exit 1
    fi
    print_success "Docker is running"
    
    # Check/Install Kind
    if ! kind version >/dev/null 2>&1; then
        print_step "Installing Kind..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install kind
        else
            curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
            chmod +x ./kind
            sudo mv ./kind /usr/local/bin/kind
        fi
    fi
    print_success "Kind is available"
    
    # Check/Install kubectl
    if ! kubectl version --client >/dev/null 2>&1; then
        print_step "Installing kubectl..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install kubectl
        else
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/
        fi
    fi
    print_success "kubectl is available"
}

create_kind_config() {
    print_step "Creating Kind cluster configuration..."
    
cat > kind-mixed-os-config.yaml << 'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: mixed-os-k8s
nodes:
- role: control-plane
- role: worker
- role: worker
EOF

    print_success "Kind configuration created"
}

create_cluster() {
    echo -e "${BLUE}🚀 Creating Mixed-OS Kubernetes Cluster${NC}"
    
    # Delete existing cluster if it exists
    if kind get clusters | grep -q "$CLUSTER_NAME"; then
        print_step "Deleting existing cluster..."
        kind delete cluster --name "$CLUSTER_NAME"
    fi
    
    print_step "Creating 3-node cluster (1 control-plane + 2 workers)..."
    kind create cluster --name "$CLUSTER_NAME" --config kind-mixed-os-config.yaml
    
    # Wait for cluster to be ready
    print_step "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    # Get worker node names
    WORKER_NODES=($(kubectl get nodes --no-headers -o custom-columns=":metadata.name" | grep worker))
    
    if [ ${#WORKER_NODES[@]} -lt 2 ]; then
        print_error "Expected 2 worker nodes, found ${#WORKER_NODES[@]}"
        exit 1
    fi
    
    LINUX_WORKER=${WORKER_NODES[0]}
    WINDOWS_SIM_WORKER=${WORKER_NODES[1]}
    
    print_step "Configuring mixed-OS node labels..."
    echo "   🐧 Linux worker: $LINUX_WORKER"
    echo "   🪟 Windows-sim worker: $WINDOWS_SIM_WORKER"
    
    # Configure Linux worker node
    kubectl label nodes $LINUX_WORKER nodepool=linux --overwrite
    kubectl label nodes $LINUX_WORKER os=linux --overwrite
    
    # Configure Windows-simulation worker node
    kubectl label nodes $WINDOWS_SIM_WORKER nodepool=windows-sim --overwrite
    kubectl label nodes $WINDOWS_SIM_WORKER os=windows-sim --overwrite
    kubectl taint nodes $WINDOWS_SIM_WORKER os=windows-sim:NoSchedule --overwrite
    
    print_success "Mixed-OS cluster configured successfully!"
}

show_cluster_info() {
    echo -e "${BLUE}📊 Cluster Information${NC}"
    echo ""
    
    echo -e "${YELLOW}Cluster Name:${NC} $CLUSTER_NAME"
    echo ""
    
    echo -e "${YELLOW}Nodes:${NC}"
    kubectl get nodes -o custom-columns="NAME:.metadata.name,STATUS:.status.conditions[?(@.type=='Ready')].status,ROLES:.metadata.labels.node-role\.kubernetes\.io/control-plane,OS:.metadata.labels.os,NODEPOOL:.metadata.labels.nodepool"
    
    echo ""
    echo -e "${YELLOW}Cluster Context:${NC}"
    kubectl config current-context
    
    echo ""
    echo -e "${GREEN}🎉 Mixed-OS Kubernetes Cluster Ready!${NC}"
    echo ""
    echo -e "${BLUE}Usage Examples:${NC}"
    echo "   # Deploy to Linux node:"
    echo "   kubectl run linux-app --image=nginx --overrides='{\"spec\":{\"nodeSelector\":{\"nodepool\":\"linux\"}}}'"
    echo ""
    echo "   # Deploy to Windows-sim node:"
    echo "   kubectl run windows-app --image=mcr.microsoft.com/windows/nanoserver:ltsc2022 --overrides='{\"spec\":{\"nodeSelector\":{\"nodepool\":\"windows-sim\"},\"tolerations\":[{\"key\":\"os\",\"value\":\"windows-sim\",\"effect\":\"NoSchedule\"}]}}'"
    echo ""
    echo "   # Check node labels:"
    echo "   kubectl get nodes --show-labels"
}

cleanup_files() {
    print_step "Cleaning up configuration files..."
    rm -f kind-mixed-os-config.yaml
    print_success "Configuration files cleaned up"
}

main() {
    echo -e "${BLUE}🤖 Simple Mixed-OS Kubernetes Cluster Deployment${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    
    check_prerequisites
    create_kind_config
    create_cluster
    show_cluster_info
    cleanup_files
    
    echo ""
    print_success "Mixed-OS cluster deployment complete!"
    echo -e "${YELLOW}💡 Your cluster is ready for mixed-OS workloads${NC}"
}

main "$@"