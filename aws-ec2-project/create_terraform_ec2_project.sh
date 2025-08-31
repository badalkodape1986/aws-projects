#!/bin/bash
# 🚀 Generator: Terraform AWS EC2 Project
# Author: You 😎

set -e
BASE_DIR="aws-ec2-projects/terraform/ec2-instance"
mkdir -p $BASE_DIR

# ============================
# main.tf
# ============================
cat > $BASE_DIR/main.tf <<'EOF'
provider "aws" {
  region = var.region
}

# Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH and HTTP access"

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
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.ec2_sg.name]

  user_data = <<-EOT
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y nginx
              echo "Hello from Terraform EC2!" | sudo tee /var/www/html/index.html
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
  default     = "terraform-ec2"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance (Amazon Linux/Ubuntu)"
  type        = string
  default     = "ami-08c40ec9ead489470" # Ubuntu 22.04 LTS in us-east-1
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
output "ec2_instance_id" {
  value = aws_instance.web.id
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
# ☁️ Terraform AWS EC2 Project

This project provisions an **EC2 instance on AWS** using Terraform.

---

## 🚀 Features
- Creates a Security Group with **SSH (22)** and **HTTP (80)** access
- Launches an EC2 instance with a chosen **AMI**, **instance type**, and **key pair**
- Installs **Nginx automatically** using `user_data`
- Outputs EC2 **ID, Public IP, and DNS**

---

## 📘 Usage

### 1. Navigate into the project
```bash
cd aws-ec2-projects/terraform/ec2-instance

