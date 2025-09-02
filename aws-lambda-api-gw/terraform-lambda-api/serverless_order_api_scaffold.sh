#!/bin/bash
# serverless_order_api_scaffold.sh
# Scaffolds Terraform project for Serverless Order API (Lambda + API Gateway + DynamoDB)

set -e

echo "🚀 Generating Terraform project: Serverless Order API"

# -------------------------------
# main.tf
# -------------------------------
cat > main.tf <<'EOF'
provider "aws" {
  region = var.region
}

# DynamoDB Table
resource "aws_dynamodb_table" "orders" {
  name         = "Orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "orderId"

  attribute {
    name = "orderId"
    type = "S"
  }

  tags = {
    Name = "Orders"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-dynamodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Package Lambda Function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/function.zip"
}

# Lambda Function
resource "aws_lambda_function" "order_function" {
  function_name = "OrderFunction"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.lambda_zip.output_path
}

# API Gateway
resource "aws_api_gateway_rest_api" "order_api" {
  name        = "OrderAPI"
  description = "Serverless Order API"
}

data "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  path        = "/"
}

resource "aws_api_gateway_resource" "order_resource" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  parent_id   = data.aws_api_gateway_resource.root.id
  path_part   = "order"
}

resource "aws_api_gateway_method" "order_post" {
  rest_api_id   = aws_api_gateway_rest_api.order_api.id
  resource_id   = aws_api_gateway_resource.order_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "order_integration" {
  rest_api_id             = aws_api_gateway_rest_api.order_api.id
  resource_id             = aws_api_gateway_resource.order_resource.id
  http_method             = aws_api_gateway_method.order_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.order_function.invoke_arn
}

resource "aws_api_gateway_deployment" "order_deploy" {
  depends_on  = [aws_api_gateway_integration.order_integration]
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  stage_name  = "dev"
}

# Allow API Gateway to call Lambda
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.order_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.order_api.execution_arn}/*/POST/order"
}

# Outputs
output "api_url" {
  description = "Invoke URL for the Order API"
  value       = "${aws_api_gateway_deployment.order_deploy.invoke_url}/order"
}
EOF

# -------------------------------
# lambda_function.py
# -------------------------------
cat > lambda_function.py <<'EOF'
import json
import boto3
import uuid

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("Orders")

def lambda_handler(event, context):
    body = json.loads(event["body"])
    order_id = str(uuid.uuid4())
    
    table.put_item(Item={
        "orderId": order_id,
        "product": body["product"],
        "quantity": body["quantity"],
        "status": "PLACED"
    })
    
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Order placed successfully", "orderId": order_id})
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
# 📘 Serverless Order API (Terraform)

This project provisions:
- **DynamoDB Table**: `Orders`
- **Lambda Function**: `OrderFunction`
- **API Gateway**: `/order` endpoint (POST)

---

## 🔹 Setup

1. Update **terraform.tfvars**:
   ```hcl
   region = "ap-south-1"

