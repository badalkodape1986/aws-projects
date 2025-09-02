#!/bin/bash
# rds_terraform_scaffold.sh
# Generates Terraform config (main.tf) + README.md for RDS MySQL + CloudWatch Alarm

set -e

echo "🚀 AWS RDS + CloudWatch Terraform Scaffolder"

# -------------------------------
# Collect User Inputs
# -------------------------------
read -p "Enter AWS Region (e.g., ap-south-1): " REGION
read -p "Enter VPC ID: " VPC_ID
read -p "Enter Subnet ID 1: " SUBNET1
read -p "Enter Subnet ID 2: " SUBNET2
read -p "Enter your IP for DB access (e.g., 1.2.3.4/32): " MYIP
read -p "Enter your email for alarm notifications: " EMAIL
read -p "Enter DB username (default: admin): " DBUSER
DBUSER=${DBUSER:-admin}
read -p "Enter DB password (min 8 chars): " DBPASS
read -p "Enter DB instance identifier (default: mydb-instance): " DBID
DBID=${DBID:-mydb-instance}
read -p "Enter DB name (default: mydb): " DBNAME
DBNAME=${DBNAME:-mydb}

# -------------------------------
# Generate main.tf
# -------------------------------
cat > main.tf <<EOF
provider "aws" {
  region = "${REGION}"
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow MySQL access"
  vpc_id      = "${VPC_ID}"

  ingress {
    description = "MySQL access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${MYIP}"]
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
  subnet_ids = ["${SUBNET1}", "${SUBNET2}"]

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_db_instance" "mydb" {
  identifier             = "${DBID}"
  engine                 = "mysql"
  engine_version         = "8.0.35"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "${DBNAME}"
  username               = "${DBUSER}"
  password               = "${DBPASS}"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = true
  backup_retention_period = 7
  multi_az               = false

  tags = {
    Name = "${DBID}"
  }
}

resource "aws_sns_topic" "rds_alarm_topic" {
  name = "rds-alarm-topic"
}

resource "aws_sns_topic_subscription" "rds_alarm_email" {
  topic_arn = aws_sns_topic.rds_alarm_topic.arn
  protocol  = "email"
  endpoint  = "${EMAIL}"
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "HighCPUAlarm-${DBID}"
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

echo "✅ main.tf generated!"

# -------------------------------
# Generate README.md
# -------------------------------
cat > README.md <<EOF
# 📘 AWS RDS (MySQL) + CloudWatch Alarm via Terraform

This project provisions:
- An **RDS MySQL database**
- A **Security Group** allowing MySQL access
- An **SNS Topic** with email subscription
- A **CloudWatch Alarm** (CPUUtilization > 70%)

---

## 🔹 Manual Steps (Console)

1. Open **AWS RDS → Create Database**.
2. Choose **MySQL**, set identifier \`${DBID}\`, user \`${DBUSER}\`.
3. Instance type: \`db.t3.micro\`, storage: 20 GB.
4. Networking: VPC = \`${VPC_ID}\`, Subnets = [\`${SUBNET1}\`, \`${SUBNET2}\`].
5. Security Group: allow \`${MYIP}\` on port 3306.
6. Enable backups (7 days), monitoring, and launch.
7. Connect:
   \`\`\`bash
   mysql -h <endpoint> -u ${DBUSER} -p
   \`\`\`
8. Create CloudWatch alarm (CPU > 70%), send to SNS → confirm email \`${EMAIL}\`.

---

## 🔹 Terraform Usage

1. Initialize:
   \`\`\`bash
   terraform init
   \`\`\`

2. Plan:
   \`\`\`bash
   terraform plan
   \`\`\`

3. Apply:
   \`\`\`bash
   terraform apply
   \`\`\`

4. Confirm SNS email subscription (check inbox).

---

## 📊 Outcome

- Managed **MySQL RDS instance** (\`${DBID}\`)  
- Secure access from \`${MYIP}\`  
- **SNS Email Alerts** to \`${EMAIL}\` if CPU > 70%  
EOF

echo "📄 README.md generated!"
echo "🎉 Project scaffold ready. Next steps: run 'terraform init && terraform apply'."

