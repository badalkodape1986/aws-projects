#!/bin/bash
# 🚀 Generator: Terraform AWS RDS Project
# Author: You 😎

set -e
BASE_DIR="aws-vpc-rds/terraform/rds-project"
mkdir -p $BASE_DIR

# ============================
# main.tf
# ============================
cat > $BASE_DIR/main.tf <<'EOF'
provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

# Public Subnet (for Bastion)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-subnet"
    Project = var.project_name
  }
}

# Private Subnet (for RDS)
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr

  tags = {
    Name    = "${var.project_name}-private-subnet"
    Project = var.project_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "${var.project_name}-rtb"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for Bastion EC2
resource "aws_security_group" "bastion_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-bastion-sg"
  description = "Allow SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-rds-sg"
  description = "Allow MySQL from Bastion"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Bastion Host (EC2)
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = {
    Name    = "${var.project_name}-bastion"
    Project = var.project_name
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "rds_subnets" {
  name       = "${var.project_name}-subnet-group"
  subnet_ids = [aws_subnet.private.id]

  tags = {
    Name    = "${var.project_name}-db-subnet-group"
    Project = var.project_name
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "mysql" {
  identifier              = "${var.project_name}-mysql"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  db_subnet_group_name    = aws_db_subnet_group.rds_subnets.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  username                = var.db_username
  password                = var.db_password
  skip_final_snapshot     = true
  publicly_accessible     = false

  tags = {
    Name    = "${var.project_name}-rds"
    Project = var.project_name
  }
}
EOF

# ============================
# variables.tf
# ============================
cat > $BASE_DIR/variables.tf <<'EOF'
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "terraform-rds"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.1.2.0/24"
}

variable "ami_id" {
  description = "AMI ID for Bastion EC2"
  type        = string
  default     = "ami-08c40ec9ead489470" # Ubuntu 22.04 LTS us-east-1
}

variable "instance_type" {
  description = "EC2 instance type for Bastion"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
}

variable "db_username" {
  description = "RDS DB username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "RDS DB password"
  type        = string
  sensitive   = true
}
EOF

# ============================
# outputs.tf
# ============================
cat > $BASE_DIR/outputs.tf <<'EOF'
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_public_dns" {
  value = aws_instance.bastion.public_dns
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}
EOF

# ============================
# README.md
# ============================
cat > $BASE_DIR/README.md <<'EOF'
# ☁️ Terraform AWS RDS Project

This project provisions a **VPC with public & private subnets**, launches a **Bastion EC2** in the public subnet, and deploys a **MySQL RDS instance** in the private subnet.

---

## 🚀 Features
- Custom VPC with Public & Private subnets
- Internet Gateway + Route Table for public subnet
- Bastion EC2 (public subnet) for SSH access
- Security Group rules:
  - Bastion → SSH from anywhere
  - RDS → allow MySQL only from Bastion SG
- RDS MySQL instance (private subnet)
- Outputs → Bastion IP/DNS + RDS Endpoint

---

## 📘 Usage

### 1. Navigate into the project
```bash
cd aws-vpc-rds/terraform/rds-project

