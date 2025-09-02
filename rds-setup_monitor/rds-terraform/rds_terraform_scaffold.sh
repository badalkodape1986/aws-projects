#!/bin/bash
# rds_terraform_scaffold.sh
# Generates Terraform config (main.tf + variables.tf + terraform.tfvars) + README.md for RDS MySQL + CloudWatch Alarm

set -e

echo "🚀 Generating Terraform project for AWS RDS + CloudWatch Alarm..."

# -------------------------------
# Generate variables.tf
# -------------------------------
cat > variables.tf <<'EOF'
variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "subnet1" {
  description = "First subnet ID for RDS subnet group"
  type        = string
}

variable "subnet2" {
  description = "Second subnet ID for RDS subnet group"
  type        = string
}

variable "my_ip" {
  description = "Your IP with CIDR for DB access (e.g., 1.2.3.4/32)"
  type        = string
}

variable "email" {
  description = "Email for CloudWatch alarm notifications"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database master password (min 8 chars)"
  type        = string
  sensitive   = true
}

variable "db_identifier" {
  description = "RDS instance identifier"
  type        = string
  default     = "mydb-instance"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "mydb"
}
EOF

# -------------------------------
# Generate terraform.tfvars (example values)
# -------------------------------
cat > terraform.tfvars <<'EOF'
region      = "ap-south-1"
vpc_id      = "vpc-1234567890abcdef"
subnet1     = "subnet-abc12345"
subnet2     = "subnet-def67890"
my_ip       = "1.2.3.4/32"
email       = "you@example.com"
db_username = "admin"
db_password = "ChangeMe123!"
db_identifier = "mydb-instance"
db_name       = "mydb"
EOF

# -------------------------------
# Generate main.tf
# -------------------------------
cat > main.tf <<'EOF'
provider "aws" {
  region = var.region
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow MySQL access"
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [var.subnet1, var.subnet2]

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_db_instance" "mydb" {
  identifier             = var.db_identifier
  engine                 = "mysql"
  engine_version         = "8.0.35"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = true
  backup_retention_period = 7
  multi_az               = false

  tags = {
    Name = var.db_identifier
  }
}

resource "aws_sns_topic" "rds_alarm_topic" {
  name = "rds-alarm-topic"
}

resource "aws_sns_topic_subscription" "rds_alarm_email" {
  topic_arn = aws_sns_topic.rds_alarm_topic.arn
  protocol  = "email"
  endpoint  = var.email
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "HighCPUAlarm-${var.db_identifier}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mydb.id
  }

  alarm_description = "Alarm when RDS CPU > 70%"
  alarm_actions     = [aws_sns_topic.rds_alarm_topic.arn]
}
EOF

# -------------------------------
# Generate README.md
# -------------------------------
cat > README.md <<'EOF'
# 📘 AWS RDS (MySQL) + CloudWatch Alarm via Terraform

This project provisions:
- An **RDS MySQL database**
- A **Security Group** allowing MySQL access
- An **SNS Topic** with email subscription
- A **CloudWatch Alarm** (CPUUtilization > 70%)

---

## 🔹 Setup

1. Edit **terraform.tfvars** with your values:
   ```hcl
   region      = "ap-south-1"
   vpc_id      = "vpc-1234567890abcdef"
   subnet1     = "subnet-abc12345"
   subnet2     = "subnet-def67890"
   my_ip       = "1.2.3.4/32"
   email       = "you@example.com"
   db_username = "admin"
   db_password = "ChangeMe123!"
   db_identifier = "mydb-instance"
   db_name       = "mydb"

