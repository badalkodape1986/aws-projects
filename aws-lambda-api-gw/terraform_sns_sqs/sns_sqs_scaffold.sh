#!/bin/bash
# sns_sqs_scaffold.sh
# Scaffolds Terraform project for SNS + SQS fan-out pattern

set -e

echo "🚀 Generating Terraform project: SNS + SQS Fan-out"

# -------------------------------
# main.tf
# -------------------------------
cat > main.tf <<'EOF'
provider "aws" {
  region = var.region
}

# SNS Topic
resource "aws_sns_topic" "order_topic" {
  name = "OrderPlacedTopic"
}

# SQS Queues
resource "aws_sqs_queue" "email_queue" {
  name = "EmailQueue"
}

resource "aws_sqs_queue" "payment_queue" {
  name = "PaymentQueue"
}

resource "aws_sqs_queue" "inventory_queue" {
  name = "InventoryQueue"
}

# SNS Subscriptions
resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.order_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.email_queue.arn
}

resource "aws_sns_topic_subscription" "payment_sub" {
  topic_arn = aws_sns_topic.order_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.payment_queue.arn
}

resource "aws_sns_topic_subscription" "inventory_sub" {
  topic_arn = aws_sns_topic.order_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.inventory_queue.arn
}

# Allow SNS to publish to SQS
resource "aws_sqs_queue_policy" "email_policy" {
  queue_url = aws_sqs_queue.email_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.email_queue.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.order_topic.arn
        }
      }
    }]
  })
}

resource "aws_sqs_queue_policy" "payment_policy" {
  queue_url = aws_sqs_queue.payment_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.payment_queue.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.order_topic.arn
        }
      }
    }]
  })
}

resource "aws_sqs_queue_policy" "inventory_policy" {
  queue_url = aws_sqs_queue.inventory_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.inventory_queue.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.order_topic.arn
        }
      }
    }]
  })
}

# Outputs
output "sns_topic_arn" {
  value = aws_sns_topic.order_topic.arn
}

output "sqs_queue_arns" {
  value = [
    aws_sqs_queue.email_queue.arn,
    aws_sqs_queue.payment_queue.arn,
    aws_sqs_queue.inventory_queue.arn
  ]
}
EOF

# -------------------------------
# variables.tf
# -------------------------------
cat > variables.tf <<'EOF'
variable "region" {
  description = "AWS region"
  type        = string
}
EOF

# -------------------------------
# terraform.tfvars
# -------------------------------
cat > terraform.tfvars <<'EOF'
region = "ap-south-1"
EOF

# -------------------------------
# README.md
# -------------------------------
cat > README.md <<'EOF'
# 📘 AWS SNS + SQS Fan-out Pattern (Terraform)

This project provisions:
- **SNS Topic**: `OrderPlacedTopic`
- **3 SQS Queues**: `EmailQueue`, `PaymentQueue`, `InventoryQueue`
- Subscriptions from SNS → SQS
- Policies to allow SNS to publish to SQS

---

## 🔹 Setup

1. Update `terraform.tfvars`:
   ```hcl
   region = "ap-south-1"

