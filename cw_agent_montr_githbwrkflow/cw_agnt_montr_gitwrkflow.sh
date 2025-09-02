#!/bin/bash
# 🚀 Auto Generator for CloudWatch Dynamic Monitoring with Terraform + GitHub Actions
# Author: Badal's GitHub Portfolio

set -e
BASE_DIR="cw_agnt_montr_gitwrkflow"
TF_DIR="$BASE_DIR/terraform"
WORKFLOW_DIR="$BASE_DIR/.github/workflows"

mkdir -p $TF_DIR/env
mkdir -p $WORKFLOW_DIR

# ============================
# Terraform: main.tf (provider + default tags)
# ============================
cat > $TF_DIR/main.tf <<'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "CloudWatch-Monitoring"
      Environment = terraform.workspace
      Monitoring  = "Enabled"
    }
  }
}
EOF

# ============================
# Terraform: ec2_with_cwagent.tf
# ============================
cat > $TF_DIR/ec2_with_cwagent.tf <<'EOF'
# Fetch default VPC, subnet, and latest Amazon Linux 2 AMI
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 Instance
resource "aws_instance" "monitoring_demo" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]

  user_data = <<-EOT
              #!/bin/bash
              yum update -y
              yum install -y amazon-cloudwatch-agent stress-ng

              cat <<CONFIG > /opt/aws/amazon-cloudwatch-agent/bin/config.json
              {
                "agent": {
                  "metrics_collection_interval": 60,
                  "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
                },
                "metrics": {
                  "append_dimensions": {
                    "InstanceId": "$${aws:InstanceId}"
                  },
                  "metrics_collected": {
                    "mem": {
                      "measurement": ["mem_used_percent"],
                      "metrics_collection_interval": 60
                    },
                    "disk": {
                      "measurement": ["used_percent"],
                      "metrics_collection_interval": 60,
                      "resources": ["*"]
                    }
                  }
                }
              }
              CONFIG

              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
              EOT

  tags = {
    Name       = "ec2-monitoring-demo"
    Monitoring = "Enabled"
  }
}

# Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-monitoring-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

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
}
EOF

# ============================
# Terraform: lambda + eventbridge
# ============================
cat > $TF_DIR/lambda.tf <<'EOF'
resource "aws_iam_role" "lambda_role" {
  name = "cloudwatch-monitoring-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_permissions" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_lambda_function" "cw_dynamic" {
  filename         = "${path.module}/lambda_function.zip"
  function_name    = "cw-dynamic-alarms"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "ec2_state_change" {
  name        = "ec2-state-change"
  description = "Capture EC2 instance state changes"
  event_pattern = jsonencode({
    source = ["aws.ec2"],
    "detail-type" = ["EC2 Instance State-change Notification"],
    detail = { state = ["running", "stopped", "terminated"] }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.ec2_state_change.name
  target_id = "cw-dynamic-alarms"
  arn       = aws_lambda_function.cw_dynamic.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cw_dynamic.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_state_change.arn
}
EOF

# ============================
# Terraform: sns + alarms
# ============================
cat > $TF_DIR/alarms.tf <<'EOF'
resource "aws_sns_topic" "alerts" {
  name = "ec2-monitoring-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
EOF

# ============================
# Terraform: variables.tf
# ============================
cat > $TF_DIR/variables.tf <<'EOF'
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair for SSH access"
  type        = string
}
EOF

# ============================
# Terraform: outputs.tf
# ============================
cat > $TF_DIR/outputs.tf <<'EOF'
output "ec2_public_ip" {
  description = "Public IP of the EC2 monitoring instance"
  value       = aws_instance.monitoring_demo.public_ip
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for CloudWatch alarms"
  value       = aws_sns_topic.alerts.arn
}

output "confirmation_instructions" {
  description = "Reminder to confirm SNS subscription"
  value       = "Check your email (${var.alert_email}) and confirm the SNS subscription."
}
EOF

# ============================
# Lambda Python Function
# ============================
cat > $TF_DIR/lambda_function.py <<'EOF'
import boto3
import os

cloudwatch = boto3.client('cloudwatch')
ec2 = boto3.client('ec2')
sns_topic = os.environ['SNS_TOPIC_ARN']

def has_monitoring_tag(instance_id):
    resp = ec2.describe_tags(
        Filters=[
            {"Name": "resource-id", "Values": [instance_id]},
            {"Name": "key", "Values": ["Monitoring"]},
            {"Name": "value", "Values": ["Enabled"]}
        ]
    )
    return len(resp.get("Tags", [])) > 0

def create_alarms(instance_id):
    cloudwatch.put_metric_alarm(
        AlarmName=f"CPUUtilization-{instance_id}",
        ComparisonOperator="GreaterThanThreshold",
        EvaluationPeriods=2,
        MetricName="CPUUtilization",
        Namespace="AWS/EC2",
        Period=60,
        Statistic="Average",
        Threshold=80,
        AlarmActions=[sns_topic],
        Dimensions=[{"Name": "InstanceId", "Value": instance_id}],
    )

    cloudwatch.put_metric_alarm(
        AlarmName=f"MemoryUtilization-{instance_id}",
        ComparisonOperator="GreaterThanThreshold",
        EvaluationPeriods=2,
        MetricName="mem_used_percent",
        Namespace="CWAgent",
        Period=60,
        Statistic="Average",
        Threshold=80,
        AlarmActions=[sns_topic],
        Dimensions=[{"Name": "InstanceId", "Value": instance_id}],
    )

    cloudwatch.put_metric_alarm(
        AlarmName=f"DiskUtilization-{instance_id}",
        ComparisonOperator="GreaterThanThreshold",
        EvaluationPeriods=2,
        MetricName="disk_used_percent",
        Namespace="CWAgent",
        Period=60,
        Statistic="Average",
        Threshold=80,
        AlarmActions=[sns_topic],
        Dimensions=[
            {"Name": "InstanceId", "Value": instance_id},
            {"Name": "path", "Value": "/"},
            {"Name": "fstype", "Value": "xfs"},
        ],
    )

def delete_alarms(instance_id):
    alarm_prefixes = [
        f"CPUUtilization-{instance_id}",
        f"MemoryUtilization-{instance_id}",
        f"DiskUtilization-{instance_id}",
    ]
    for prefix in alarm_prefixes:
        alarms = cloudwatch.describe_alarms(AlarmNamePrefix=prefix)
        names = [a["AlarmName"] for a in alarms.get("MetricAlarms", [])]
        if names:
            cloudwatch.delete_alarms(AlarmNames=names)

def lambda_handler(event, context):
    detail = event.get("detail", {})
    instance_id = detail.get("instance-id")
    state = detail.get("state")

    if not instance_id or not state:
        return {"status": "ignored"}

    if state == "running":
        if has_monitoring_tag(instance_id):
            create_alarms(instance_id)
            return {"status": f"alarms created for {instance_id}"}
        return {"status": f"skipped {instance_id}, no Monitoring=Enabled tag"}

    elif state in ["stopped", "terminated"]:
        delete_alarms(instance_id)
        return {"status": f"alarms removed for {instance_id}"}

    return {"status": f"state {state} ignored"}
EOF

# ============================
# GitHub Actions Workflow
# ============================
cat > $WORKFLOW_DIR/terraform.yml <<'EOF'
name: Terraform CI/CD

on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.8.5

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Terraform Init
        run: terraform -chdir=cw_agnt_montr_gitwrkflow/terraform init

      - name: Terraform Plan
        run: terraform -chdir=cw_agnt_montr_gitwrkflow/terraform plan -no-color -input=false

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform -chdir=cw_agnt_montr_gitwrkflow/terraform apply -auto-approve -input=false
EOF

# ============================
# README.md
# ============================
cat > $BASE_DIR/README.md <<'EOF'
# 📊 CloudWatch Dynamic Monitoring with Terraform + GitHub Actions

This project automates **CloudWatch monitoring** for EC2 instances with:
- ✅ EC2 instance + CloudWatch Agent (CPU, Memory, Disk)
- ✅ CloudWatch Alarms auto-created/deleted via Lambda + EventBridge
- ✅ SNS Alerts via Email
- ✅ GitHub Actions CI/CD pipeline for Terraform

---

## 🚀 Setup Guide

### 1. Prerequisites
- AWS CLI installed & configured (`aws configure`)
- Terraform installed (>=1.5.0)
- GitHub repo for CI/CD
- IAM user with access to EC2, CloudWatch, SNS, Lambda, IAM

---

### 2. AWS Secrets in GitHub
Go to **GitHub → Repo → Settings → Secrets and variables → Actions → New repository secret**  
Add:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

---

### 3. Deploy Infrastructure

```bash
cd cw_agnt_montr_gitwrkflow/terraform
terraform init
terraform apply
