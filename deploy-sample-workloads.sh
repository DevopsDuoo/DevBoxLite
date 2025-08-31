#!/bin/bash
# filepath: /Users/hrushi/DevBoxLite/deploy-sample-workloads.sh

# Deploy sample workloads to demonstrate mixed-OS scheduling

echo "🚀 Deploying Mixed-OS Sample Workloads"
echo "======================================"

# Linux Web App
echo "🐧 Deploying Linux web application..."
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: linux-webapp
  labels:
    app: linux-webapp
    os: linux
spec:
  replicas: 2
  selector:
    matchLabels:
      app: linux-webapp
  template:
    metadata:
      labels:
        app: linux-webapp
        os: linux
    spec:
      nodeSelector:
        nodepool: linux
      containers:
      - name: webapp
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: DEPLOYMENT_TARGET
          value: "Linux Node"
        - name: APP_TYPE
          value: "Web Server"
        volumeMounts:
        - name: config
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
      volumes:
      - name: config
        configMap:
          name: linux-webapp-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: linux-webapp-config
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head><title>Linux Web App</title></head>
    <body style="font-family: Arial; background: #e8f5e8; padding: 50px; text-align: center;">
        <h1>🐧 Linux Web Application</h1>
        <p>Running on: Linux Node Pool</p>
        <p>Container OS: Alpine Linux</p>
        <p>Status: Active and Ready</p>
    </body>
    </html>
---
apiVersion: v1
kind: Service
metadata:
  name: linux-webapp-service
spec:
  selector:
    app: linux-webapp
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort
EOF

echo "🪟 Deploying Windows-simulation application..."
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: windows-sim-app
  labels:
    app: windows-sim-app
    os: windows-sim
spec:
  replicas: 1
  selector:
    matchLabels:
      app: windows-sim-app
  template:
    metadata:
      labels:
        app: windows-sim-app
        os: windows-sim
    spec:
      nodeSelector:
        nodepool: windows-sim
      tolerations:
      - key: os
        value: windows-sim
        effect: NoSchedule
      containers:
      - name: windows-sim
        image: ubuntu:20.04
        command: ["/bin/bash"]
        args: ["-c", "while true; do echo 'Windows Simulation Service Running on:' \$(hostname); echo 'Timestamp:' \$(date); echo 'Simulating Windows Service...'; sleep 30; done"]
        env:
        - name: DEPLOYMENT_TARGET
          value: "Windows-Simulation Node"
        - name: APP_TYPE
          value: "Background Service"
        - name: WINDOWS_SIM
          value: "true"
---
apiVersion: v1
kind: Service
metadata:
  name: windows-sim-service
spec:
  selector:
    app: windows-sim-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Wait for deployments
echo ""
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available deployment/linux-webapp --timeout=120s
kubectl wait --for=condition=available deployment/windows-sim-app --timeout=120s

echo ""
echo "✅ Sample workloads deployed successfully!"

echo ""
echo "📊 Deployment Status:"
kubectl get deployments -o wide
echo ""
kubectl get pods -o wide
echo ""
kubectl get services

echo ""
echo "🌐 Access Points:"
echo "   • Linux Web App: http://localhost:30080 (via kubectl port-forward or NodePort)"
echo ""
echo "📋 Verification Commands:"
echo "   kubectl get pods -o wide  # See pod placement on nodes"
echo "   kubectl logs -l app=windows-sim-app -f  # View Windows simulation logs"
echo "   kubectl port-forward svc/linux-webapp-service 8080:80  # Access web app"