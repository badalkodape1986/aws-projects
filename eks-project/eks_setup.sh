#!/bin/bash
# eks_setup.sh
# Automates setup of Amazon EKS Cluster (2 nodes) + NGINX Deployment
# Generates README.md with manual steps

set -e

CLUSTER_NAME="my-eks-cluster"
REGION="ap-south-1"
NODEGROUP_NAME="my-eks-nodes"
NODE_TYPE="t3.medium"
NODE_COUNT=2   # fixed min & max

echo "🚀 Setting up Amazon EKS cluster with eksctl..."

# -------------------------------
# Install eksctl if not available
# -------------------------------
if ! command -v eksctl &> /dev/null; then
    echo "🔹 Installing eksctl..."
    curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz"
    tar -xvzf eksctl_$(uname -s)_amd64.tar.gz -C /usr/local/bin
    rm eksctl_$(uname -s)_amd64.tar.gz
fi

# -------------------------------
# Install kubectl if not available
# -------------------------------
if ! command -v kubectl &> /dev/null; then
    echo "🔹 Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
fi

# -------------------------------
# Create EKS Cluster (2 nodes only)
# -------------------------------
echo "🔹 Creating EKS cluster..."
eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --nodegroup-name $NODEGROUP_NAME \
  --node-type $NODE_TYPE \
  --nodes $NODE_COUNT \
  --nodes-min $NODE_COUNT \
  --nodes-max $NODE_COUNT \
  --managed

echo "✅ EKS Cluster created: $CLUSTER_NAME"

# -------------------------------
# Deploy Sample App (NGINX)
# -------------------------------
echo "🔹 Deploying NGINX app..."
cat > deployment.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web-app
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: LoadBalancer
  selector:
    app: web-app
  ports:
    - port: 80
      targetPort: 80
YAML

kubectl apply -f deployment.yaml
echo "✅ NGINX app deployed!"

# -------------------------------
# Generate README.md
# -------------------------------
cat > README.md <<EOF
# 📘 Amazon EKS – Kubernetes on AWS (2-node cluster)

This project provisions:
- An **EKS Cluster** (\`$CLUSTER_NAME\`)
- A **Managed Node Group** (\`$NODEGROUP_NAME\`) with exactly 2 nodes
- A **Sample NGINX Deployment** exposed via LoadBalancer

---

## 🔹 Manual Steps (Console + CLI)

### Step 1: Create EKS Cluster
1. Go to **EKS → Create cluster**
2. Name: \`$CLUSTER_NAME\`
3. IAM Role: must have \`AmazonEKSClusterPolicy\`
4. Select VPC, subnets, security group
5. Enable control plane logging
6. Click **Create**

### Step 2: Create Node Group
1. Go to **EKS → Compute → Add Node Group**
2. Name: \`$NODEGROUP_NAME\`
3. IAM role with \`AmazonEKSWorkerNodePolicy\`
4. Instance type: \`$NODE_TYPE\`
5. Min: $NODE_COUNT, Max: $NODE_COUNT
6. Create node group (exactly 2 nodes)

### Step 3: Configure kubectl
```bash
aws eks --region $REGION update-kubeconfig --name $CLUSTER_NAME

