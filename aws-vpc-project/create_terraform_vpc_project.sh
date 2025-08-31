#!/bin/bash
# 🚀 Generator: Terraform AWS VPC Project
# Author: You 😎

set -e
BASE_DIR="aws-vpc-terraform/terraform/vpc-project"
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

# Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-subnet"
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

# Route Table
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

# Route Table Association
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "web_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-sg"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOT
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y nginx
              echo "Hello from Terraform VPC Project!" | sudo tee /var/www/html/index.html
              sudo systemctl enable nginx
              sudo systemctl start nginx
              EOT

  tags = {
    Name    = "${var.project_name}-ec2"
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
  default     = "terraform-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ami_id" {
  description = "AMI ID for EC2 (Ubuntu 22.04 in us-east-1 by default)"
  type        = string
  default     = "ami-08c40ec9ead489470"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of an existing AWS key pair"
  type        = string
}
EOF

# ============================
# outputs.tf
# ============================
cat > $BASE_DIR/outputs.tf <<'EOF'
output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id" {
  value = aws_subnet.public.id
}

output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}

output "ec2_public_dns" {
  value = aws_instance.web.public_dns
}
EOF

# ============================
# README.md
# ============================
cat > $BASE_DIR/README.md <<'EOF'
# ☁️ Terraform AWS VPC Project

This project provisions a **custom VPC with public subnet** and launches an **EC2 instance with Nginx**.

---

## 🚀 Features
- Creates VPC with CIDR block (default: 10.0.0.0/16)
- Creates a public Subnet (default: 10.0.1.0/24)
- Internet Gateway + Route Table with default route
- Security Group with SSH (22) + HTTP (80)
- EC2 instance inside subnet (with Nginx auto-installed)

---

## 📘 Usage

### 1. Navigate into the project
```bash
cd aws-vpc-terraform/terraform/vpc-project

