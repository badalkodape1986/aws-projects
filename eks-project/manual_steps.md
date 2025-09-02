📘 Project 13: Amazon EKS – Kubernetes on AWS
🔹 Why EKS?

You already built apps on EC2, ALB, RDS, ECS, Lambda, SQS/SNS.

EKS is the enterprise-grade Kubernetes solution → lets you run microservices at scale.

Used in production for container orchestration when ECS isn’t enough.

Brings together:

Kubernetes (pods, deployments, services)

AWS infra (VPC, IAM, Load Balancer, EBS, CloudWatch, etc.)

🔹 Part 1: Manual Setup (Console + CLI)

⚠️ Note: Setting up EKS manually is long & tricky — AWS recommends CLI/IaC, but here’s the flow:

Step 1: Create EKS Cluster

Go to EKS → Create Cluster.

Name: my-eks-cluster.

Role: IAM role with AmazonEKSClusterPolicy.

Networking: choose VPC + subnets + security group.

Logging: enable API, audit logs.

Click Create.

Step 2: Create Node Group

Go to EKS → Compute → Add Node Group.

Name: my-eks-nodes.

IAM role: with AmazonEKSWorkerNodePolicy.

Instance type: t3.medium.

Min: 2, Max: 4.

Create node group → this spins up EC2 worker nodes.

Step 3: Update kubeconfig

Install eksctl + kubectl:

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz"
tar -xvzf eksctl_$(uname -s)_amd64.tar.gz -C /usr/local/bin
kubectl version --client


Configure cluster:

aws eks --region ap-south-1 update-kubeconfig --name my-eks-cluster

Step 4: Deploy App

Create deployment.yaml:

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


Apply:

kubectl apply -f deployment.yaml


Check LoadBalancer DNS:

kubectl get svc web-service


Open in browser → NGINX served via AWS ALB. 🎉
