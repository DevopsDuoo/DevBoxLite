# Mixed-OS Kubernetes Cluster Setup

Deploy a Kubernetes cluster with both Linux and Windows-simulation nodes using Kind (Kubernetes in Docker).

## 🎯 **What This Creates**

- **3-node Kubernetes cluster** running in Docker containers
- **1 Control Plane** (Linux)
- **1 Linux Worker** node for Linux workloads
- **1 Windows-Simulation Worker** node for Windows workloads
- **Proper workload isolation** using taints, tolerations, and node selectors

## 🚀 **Quick Start**

### **1. Deploy the Cluster**
```bash
# Make the deployment script executable and run it
chmod +x deploy-mixed-os.sh
./deploy-mixed-os.sh
```

### **2. Deploy Sample Applications**
```bash
# Deploy Linux and Windows-simulation apps
kubectl apply -f mixed-os-apps.yaml
```

### **3. Verify Deployment**
```bash
# Check nodes are ready
kubectl get nodes

# Check pods are scheduled correctly
kubectl get pods -o wide

# View services
kubectl get svc
```

### **4. Access Windows-Simulation App**
```bash
# Port forward to access from browser
kubectl port-forward service/windows-sim-service 8080:80

# Then visit: http://localhost:8080
```

## 📋 **Detailed Steps**

### **Step 1: Prerequisites Check**
The deployment script will automatically:
- ✅ Check if Docker is running
- ✅ Install Kind if not present (via Homebrew)
- ✅ Install kubectl if not present

### **Step 2: Cluster Creation**
```bash
# The script creates a 3-node cluster using:
kind create cluster --name my-cluster --config mixed-os-kind-config.yaml
```

### **Step 3: Node Configuration**
```bash
# Automatically applies node labels and taints:
# Linux worker: nodepool=linux
# Windows-sim worker: nodepool=windows-sim + taint os=windows-sim:NoSchedule
```

### **Step 4: Application Deployment**
```bash
# Deploys two applications:
# - Linux Nginx (2 replicas) → Linux node only
# - Windows-sim Web (1 replica) → Windows-sim node only
kubectl apply -f mixed-os-apps.yaml
```

## 🔍 **Verification Commands**

### **Check Cluster Status**
```bash
# View all nodes and their status
kubectl get nodes -o wide

# Check node labels
kubectl get nodes --show-labels

# View node taints
kubectl describe nodes
```

### **Check Application Status**
```bash
# View all pods with node placement
kubectl get pods -o wide

# Check specific app pods
kubectl get pods -l app=linux-app
kubectl get pods -l app=windows-app

# View pod logs
kubectl logs -l app=windows-app
```

### **Check Services**
```bash
# List all services
kubectl get svc

# Check service endpoints
kubectl get endpoints
```

## 🌐 **Accessing Applications**

### **Linux Nginx App**
```bash
# Method 1: NodePort from inside cluster
docker exec my-cluster-control-plane curl http://localhost:30080

# Method 2: Port forward
kubectl port-forward service/linux-service 8081:80
# Visit: http://localhost:8081
```

### **Windows-Simulation App**
```bash
# Method 1: Port forward (Recommended)
kubectl port-forward service/windows-sim-service 8080:80
# Visit: http://localhost:8080

# Method 2: NodePort from inside cluster
docker exec my-cluster-control-plane curl http://localhost:30090
```

## 🛠️ **Troubleshooting**

### **If Deployment Fails**
```bash
# Check Kind cluster status
kind get clusters

# View cluster logs
kind get kubeconfig --name my-cluster

# Delete and recreate cluster
kind delete cluster --name my-cluster
./deploy-mixed-os.sh
```

### **If Pods Are Pending**
```bash
# Check pod events
kubectl describe pod <pod-name>

# Check node resources
kubectl describe nodes

# Verify node labels and taints
kubectl get nodes --show-labels
```

### **If Port Forward Fails**
```bash
# Check if pod is running
kubectl get pods -l app=windows-app

# Check service configuration
kubectl describe svc windows-sim-service

# Try direct pod port forward
kubectl port-forward deployment/windows-sim-app 8080:80
```

## 🧹 **Cleanup**

### **Delete Applications**
```bash
kubectl delete -f mixed-os-apps.yaml
```

### **Delete Cluster**
```bash
kind delete cluster --name my-cluster
```

### **Remove Docker Containers**
```bash
# List Kind containers
docker ps -a | grep my-cluster

# Remove all Kind containers
docker rm -f $(docker ps -aq --filter "name=my-cluster")
```

## 📁 **File Structure**

```
DevBoxLite/
├── README.md                    # This file
├── deploy-mixed-os.sh          # Main deployment script
├── mixed-os-kind-config.yaml   # Kind cluster configuration
└── mixed-os-apps.yaml          # Sample applications
```

## 🎯 **Key Concepts Demonstrated**

### **Node Scheduling**
- **NodeSelector**: Routes pods to specific node types
- **Taints & Tolerations**: Prevents/allows pod scheduling on tainted nodes
- **Labels**: Identifies nodes for workload placement

### **Mixed-OS Simulation**
- **Linux Node**: Runs standard Linux containers (nginx)
- **Windows-Sim Node**: Simulates Windows environment with taints
- **Workload Isolation**: Each app type runs only on its designated node

### **Service Exposure**
- **NodePort Services**: Expose apps on specific ports
- **Port Forwarding**: Access apps from local machine
- **Service Discovery**: Apps can communicate via service names

## 🎉 **Success Indicators**

When everything is working correctly, you should see:

```bash
$ kubectl get nodes
NAME                       STATUS   ROLES           AGE     VERSION
my-cluster-control-plane   Ready    control-plane   5m30s   v1.33.1
my-cluster-linux-worker    Ready    <none>          5m15s   v1.33.1
my-cluster-windows-sim     Ready    <none>          5m15s   v1.33.1

$ kubectl get pods -o wide
NAME                               READY   STATUS    RESTARTS   AGE   NODE
linux-nginx-xxx-xxx               1/1     Running   0          2m    my-cluster-linux-worker
linux-nginx-xxx-yyy               1/1     Running   0          2m    my-cluster-linux-worker
windows-sim-app-xxx-zzz           1/1     Running   0          2m    my-cluster-windows-sim

$ curl http://localhost:8080 (after port-forward)
# Should return Windows-Simulation App HTML page
```

Your mixed-OS Kubernetes cluster is now ready for development and testing! 🚀