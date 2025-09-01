#!/bin/bash
# 🚀 Generator: AWS CloudWatch Dynamic Monitoring Project
# Author: You 😎

set -e
BASE_DIR="cloudwatch-monitoring-dynamic"
TF_DIR="$BASE_DIR/terraform"

mkdir -p $TF_DIR

# ============================
# Lambda Function
# ============================
cat > $BASE_DIR/lambda_monitor.py <<'EOF'
import boto3
import os

cloudwatch = boto3.client("cloudwatch")
ec2 = boto3.client("ec2")

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")

def create_alarms(instance_id):
    print(f"Creating alarms for {instance_id}")

    cloudwatch.put_metric_alarm(
        AlarmName=f"HighCPU-{instance_id}",
        ComparisonOperator="GreaterThanThreshold",
        EvaluationPeriods=1,
        MetricName="CPUUtilization",
        Namespace="AWS/EC2",
        Period=300,
        Statistic="Average",
        Threshold=80.0,
        ActionsEnabled=True,
        AlarmActions=[SNS_TOPIC_ARN],
        Dimensions=[{"Name": "InstanceId", "Value": instance_id}],
        Unit="Percent"
    )

    cloudwatch.put_metric_alarm(
        AlarmName=f"HighMemory-{instance_id}",
        ComparisonOperator="GreaterThanThreshold",
        EvaluationPeriods=1,
        MetricName="mem_used_percent",
        Namespace="CWAgent",
        Period=300,
        Statistic="Average",
        Threshold=80.0,
        ActionsEnabled=True,
        AlarmActions=[SNS_TOPIC_ARN],
        Dimensions=[{"Name": "InstanceId", "Value": instance_id}]
    )

    cloudwatch.put_metric_alarm(
        AlarmName=f"HighDisk-{instance_id}",
        ComparisonOperator="GreaterThanThreshold",
        EvaluationPeriods=1,
        MetricName="disk_used_percent",
        Namespace="CWAgent",
        Period=300,
        Statistic="Average",
        Threshold=80.0,
        ActionsEnabled=True,
        AlarmActions=[SNS_TOPIC_ARN],
        Dimensions=[{"Name": "InstanceId", "Value": instance_id}]
    )

def delete_alarms(instance_id):
    print(f"Deleting alarms for {instance_id}")
    alarm_names = [
        f"HighCPU-{instance_id}",
        f"HighMemory-{instance_id}",
        f"HighDisk-{instance_id}"
    ]
    cloudwatch.delete_alarms(AlarmNames=alarm_names)

def lambda_handler(event, context):
    print("Event:", event)

    detail_type = event.get("detail-type")
    detail = event.get("detail", {})

    if detail_type == "EC2 Instance State-change Notification":
        state = detail.get("state")
        instance_id = detail.get("instance-id")

        if state == "running":
            create_alarms(instance_id)

        elif state == "terminated" or state == "stopped":
            delete_alarms(instance_id)

    return {"status": "done"}
EOF

# ============================
# Terraform Files
# ============================
cat > $TF_DIR/main.tf <<'EOF'
provider "aws" {
  region = var.region
}

resource "aws_sns_topic" "alerts" {
  name = "ec2-monitoring-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_iam_role" "lambda_role" {
  name = "ec2-monitoring-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}
resource "aws_iam_role_policy_attachment" "sns" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}
resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "ec2_monitor" {
  function_name = "ec2-monitoring-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_monitor.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  filename         = "${path.module}/lambda_monitor.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_monitor.zip")

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "ec2_events" {
  name        = "ec2-state-change"
  description = "Trigger on EC2 state changes"
  event_pattern = jsonencode({
    "source": ["aws.ec2"],
    "detail-type": ["EC2 Instance State-change Notification"]
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.ec2_events.name
  target_id = "EC2Lambda"
  arn       = aws_lambda_function.ec2_monitor.arn
}

resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_events.arn
}
EOF

cat > $TF_DIR/variables.tf <<'EOF'
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
}
EOF

cat > $TF_DIR/outputs.tf <<'EOF'
output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.ec2_monitor.function_name
}
EOF

# ============================
# README.md
# ============================
cat > $BASE_DIR/README.md <<'EOF'
# 📊 AWS Project 4 (Advanced): Dynamic CloudWatch Monitoring & Alerts

This project automates **CloudWatch monitoring** for **all EC2 instances** using **Lambda + EventBridge + SNS + Terraform**.

✅ Features:
- Automatically create **CPU, Memory, and Disk alarms** when new EC2 instances are launched.  
- Create alarms for **existing EC2** instances (one-time scan).  
- Automatically **delete alarms** when EC2 instances are stopped or terminated.  
- Send alerts via **SNS Email/SMS**.  

---

## 🚀 Deployment

### 1. Package Lambda
```bash
cd cloudwatch-monitoring-dynamic/terraform
zip lambda_monitor.zip ../lambda_monitor.py