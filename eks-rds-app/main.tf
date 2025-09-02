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
}

# Public Subnets
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true
}

# Private Subnets
resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}a"
}
resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.region}b"
}

# NAT Gateway
resource "aws_eip" "nat_eip" { vpc = true }
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public1.id
}

# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
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
    Statement = [{ Effect = "Allow", Principal = { Service = "eks.amazonaws.com" }, Action = "sts:AssumeRole" }]
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
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
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
resource "aws_iam_role_policy_attachment" "ec2_registry" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# -------------------------------
# EKS Cluster + Node Group
# -------------------------------
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config { subnet_ids = [aws_subnet.public1.id, aws_subnet.public2.id, aws_subnet.private1.id, aws_subnet.private2.id] }
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.private1.id, aws_subnet.private2.id]
  scaling_config { desired_size = 2 min_size = 2 max_size = 2 }
  instance_types = [var.node_type]
  depends_on = [aws_iam_role_policy_attachment.eks_worker_node, aws_iam_role_policy_attachment.eks_cni, aws_iam_role_policy_attachment.ec2_registry]
}

# -------------------------------
# RDS PostgreSQL
# -------------------------------
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.eks_vpc.id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}
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

# -------------------------------
# Kubernetes Provider
# -------------------------------
provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
data "aws_eks_cluster_auth" "cluster" { name = aws_eks_cluster.eks.name }

# -------------------------------
# Kubernetes Secret (DB creds)
# -------------------------------
resource "kubernetes_secret" "db_credentials" {
  metadata { name = "db-credentials" }
  data = {
    DB_HOST     = base64encode(aws_db_instance.rds.endpoint)
    DB_USER     = base64encode(var.db_username)
    DB_PASSWORD = base64encode(var.db_password)
    DB_NAME     = base64encode(aws_db_instance.rds.name)
  }
}

# -------------------------------
# Node.js App Deployment
# -------------------------------
resource "kubernetes_deployment" "node_app" {
  metadata { name = "node-app" labels = { app = "node-app" } }
  spec {
    replicas = 2
    selector { match_labels = { app = "node-app" } }
    template {
      metadata { labels = { app = "node-app" } }
      spec {
        container {
          name  = "node-app"
          image = "badalkodape/node-postgres-app:latest" # <-- replace with your image
          port { container_port = 3000 }

          env { name = "DB_HOST" value_from { secret_key_ref { name = "db-credentials" key = "DB_HOST" } } }
          env { name = "DB_USER" value_from { secret_key_ref { name = "db-credentials" key = "DB_USER" } } }
          env { name = "DB_PASSWORD" value_from { secret_key_ref { name = "db-credentials" key = "DB_PASSWORD" } } }
          env { name = "DB_NAME" value_from { secret_key_ref { name = "db-credentials" key = "DB_NAME" } } }
        }
      }
    }
  }
}

# -------------------------------
# Node.js App Service (LB)
# -------------------------------
resource "kubernetes_service" "node_app_service" {
  metadata { name = "node-app-service" }
  spec {
    selector = { app = "node-app" }
    port { port = 80 target_port = 3000 }
    type = "LoadBalancer"
  }
}

# -------------------------------
# Outputs
# -------------------------------
output "app_url" { value = kubernetes_service.node_app_service.status[0].load_balancer[0].ingress[0].hostname }
output "rds_endpoint" { value = aws_db_instance.rds.endpoint }
