# Kind (Kubernetes in Docker) Setup

Kind runs Kubernetes clusters using Docker containers as nodes.

## Prerequisites
- Docker installed and running
- kubectl installed

## Installation

### Install Kind
```bash
# On macOS
brew install kind

# Or download binary directly
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

### Install kubectl (if not already installed)
```bash
# On macOS
brew install kubectl
```

## Usage

### Create a cluster
```bash
kind create cluster --name my-cluster
```

### Create cluster with custom config
```bash
kind create cluster --config kind-config.yaml --name my-cluster
```

### List clusters
```bash
kind get clusters
```

### Delete cluster
```bash
kind delete cluster --name my-cluster
```

### Get cluster info
```bash
kubectl cluster-info --context kind-my-cluster
```

## Verify Installation
```bash
kubectl get nodes
kubectl get pods -A
```
