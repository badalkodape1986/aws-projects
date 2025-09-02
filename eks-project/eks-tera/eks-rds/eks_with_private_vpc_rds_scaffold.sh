#!/bin/bash
# eks_with_private_vpc_rds_scaffold.sh
# Scaffolds Terraform project for:
# 1. Custom VPC (Public + Private + IGW + NAT)
# 2. EKS Cluster inside Private subnets
# 3. Managed RDS PostgreSQL inside Private subnets
# 4. NGINX Deployment (K8s LoadBalancer service)

set -e

echo "🚀 Generating Terraform project: Custom VPC + EKS + RDS + NGINX"

# -------------------------------
# main.tf
# -------------------------------
cat > main.tf <<'EOF'
provider "aws" {
  region = var.region
}

# -------------------------------
# VPC + Networking
# -------------------------------
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "eks-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags   = { Name = "eks-igw" }
}

# Public Subnets
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags = { Name = "eks-public-1" }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true
  tags = { Name = "eks-public-2" }
}

# Private Subnets
resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}a"
  tags              = { Name = "eks-private-1" }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.region}b"
  tags              = { Name = "eks-private-2" }
}

# NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public1.id
  tags          = { Name = "eks-nat" }
}

# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "eks-public-rt" }
}

resource "aws_route_table_association" "pub1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pub2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "eks-private-rt" }
}

resource "aws_route_table_association" "pvt1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "pvt2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private_rt.id
}

# -------------------------------
# IAM Roles for EKS
# -------------------------------
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# -------------------------------
# EKS Cluster
# -------------------------------
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public1.id,
      aws_subnet.public2.id,
      aws_subnet.private1.id,
      aws_subnet.private2.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.private1.id, aws_subnet.private2.id]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  instance_types = [var.node_type]

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.ec2_container_registry
  ]
}

# -------------------------------
# RDS PostgreSQL (Private Subnets)
# -------------------------------
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "eks-rds-subnet-group"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]
}

resource "aws_db_instance" "rds" {
  identifier           = "eks-rds-db"
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  name                 = "appdb"
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true
}

resource "aws_security_group" "rds_sg" {
  name   = "eks-rds-sg"
  vpc_id = aws_vpc.eks_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # allow only inside VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------
# Kubernetes Provider
# -------------------------------
provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks.name
}

# -------------------------------
# NGINX Deployment
# -------------------------------
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "web-app"
    labels = { app = "web-app" }
  }

  spec {
    replicas = 2
    selector { match_labels = { app = "web-app" } }
    template {
      metadata { labels = { app = "web-app" } }
      spec {
        container {
          name  = "web-app"
          image = "nginx"
          port { container_port = 80 }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx_service" {
  metadata { name = "web-service" }
  spec {
    selector = { app = kubernetes_deployment.nginx.metadata[0].labels.app }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

# -------------------------------
# Outputs
# -------------------------------
output "eks_cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "nginx_lb_hostname" {
  value = kubernetes_service.nginx_service.status[0].load_balancer[0].ingress[0].hostname
}

output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}

output "rds_db_name" {
  value = aws_db_instance.rds.name
}
EOF

# -------------------------------
# variables.tf
# -------------------------------
cat > variables.tf <<'EOF'
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
  default     = "my-eks-cluster"
}

variable "node_group_name" {
  description = "EKS Node Group name"
  type        = string
  default     = "my-eks-nodes"
}

variable "node_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "db_username" {
  description = "RDS database username"
  type        = string
}

variable "db_password" {
  description = "RDS database password"
  type        = string
  sensitive   = true
}
EOF

# -------------------------------
# terraform.tfvars
# -------------------------------
cat > terraform.tfvars <<'EOF'
region          = "us-east-1"
cluster_name    = "my-eks-cluster"
node_group_name = "my-eks-nodes"
node_type       = "t3.medium"

db_username     = "dbadmin"
db_password     = "SuperSecretPass123"
EOF

# -------------------------------
# README.md
# -------------------------------
cat > README.md <<'EOF'
# 📘 Amazon EKS with Custom VPC + RDS (Terraform)

This project provisions:
1. A **Custom VPC** with:
   - 2 Public Subnets (LoadBalancers)
   - 2 Private Subnets (EKS + RDS)
   - IGW + NAT Gateway
2. An **EKS Cluster** in private subnets
3. A **Node Group** (2 nodes, fixed size)
4. A **PostgreSQL RDS Database** (private-only)
5. A **NGINX Deployment** exposed via LoadBalancer

---

## 🔹 Setup

1. Run scaffold script:
   ```bash
   ./eks_with_private_vpc_rds_scaffold.sh

