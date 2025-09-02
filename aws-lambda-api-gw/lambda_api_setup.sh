#!/bin/bash
# lambda_api_setup.sh
# Automates Serverless Order API with Lambda + API Gateway + DynamoDB

set -e

REGION="ap-south-1"
TABLE_NAME="Orders"
LAMBDA_NAME="OrderFunction"
ROLE_NAME="LambdaDynamoDBRole"
API_NAME="OrderAPI"

# -------------------------------
# Create DynamoDB Table
# -------------------------------
echo "🔹 Creating DynamoDB table..."
aws dynamodb create-table \
  --table-name $TABLE_NAME \
  --attribute-definitions AttributeName=orderId,AttributeType=S \
  --key-schema AttributeName=orderId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION
echo "✅ DynamoDB table created: $TABLE_NAME"

# -------------------------------
# Create IAM Role
# -------------------------------
echo "🔹 Creating IAM Role for Lambda..."
ROLE_ARN=$(aws iam create-role \
  --role-name $ROLE_NAME \
  --assume-role-policy-document '{
      "Version":"2012-10-17",
      "Statement":[{
          "Effect":"Allow",
          "Principal":{"Service":"lambda.amazonaws.com"},
          "Action":"sts:AssumeRole"
      }]
  }' \
  --query "Role.Arn" --output text)

aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

echo "⏳ Waiting for role to propagate..."
sleep 15

# -------------------------------
# Create Lambda Function
# -------------------------------
echo "🔹 Creating Lambda function..."
cat > lambda_function.py <<'PYCODE'
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
PYCODE

zip function.zip lambda_function.py
aws lambda create-function \
  --function-name $LAMBDA_NAME \
  --zip-file fileb://function.zip \
  --handler lambda_function.lambda_handler \
  --runtime python3.9 \
  --role $ROLE_ARN \
  --region $REGION
echo "✅ Lambda created: $LAMBDA_NAME"

# -------------------------------
# Create API Gateway
# -------------------------------
echo "🔹 Creating API Gateway..."
API_ID=$(aws apigateway create-rest-api --name $API_NAME --region $REGION --query 'id' --output text)
PARENT_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[0].id' --output text)

# Create /order resource
RESOURCE_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $PARENT_ID \
  --path-part order \
  --region $REGION \
  --query 'id' --output text)

# Create POST method
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --authorization-type "NONE" \
  --region $REGION

aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:$(aws sts get-caller-identity --query Account --output text):function:$LAMBDA_NAME/invocations \
  --region $REGION

# Deploy
aws apigateway create-deployment --rest-api-id $API_ID --stage-name dev --region $REGION

# Add permission for API Gateway to invoke Lambda
aws lambda add-permission \
  --function-name $LAMBDA_NAME \
  --statement-id apigateway-test-2 \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn arn:aws:execute-api:$REGION:$(aws sts get-caller-identity --query Account --output text):$API_ID/*/POST/order \
  --region $REGION

ENDPOINT="https://$API_ID.execute-api.$REGION.amazonaws.com/dev/order"
echo "✅ API Gateway deployed. Test with:"
echo "curl -X POST -H 'Content-Type: application/json' -d '{\"product\":\"Laptop\",\"quantity\":1}' $ENDPOINT"

# -------------------------------
# Generate README.md
# -------------------------------
cat > README.md <<EOF
# 📘 Serverless Order API (Lambda + API Gateway + DynamoDB)

This project provisions:
- DynamoDB table (\`Orders\`)
- Lambda function (\`$LAMBDA_NAME\`)
- API Gateway (\`$API_NAME\`) with POST /order

---

## 🔹 Manual Steps
1. Create DynamoDB table \`Orders\` (PK=orderId).
2. Create Lambda with Python code to insert orders into DynamoDB.
3. Create API Gateway → resource /order → POST → Lambda integration.
4. Deploy API → Stage = dev.
5. Test with curl:
   \`\`\`bash
[O   curl -X POST -H "Content-Type: application/json" -d '{"product":"Laptop","quantity":1}' $ENDPOINT
   \`\`\`

---

## 🔹 Scripted Setup
Run:
\`\`\`bash
./lambda_api_setup.sh
\`\`\`

It will:
- Create DynamoDB
- Create IAM Role
- Deploy Lambda
- Configure API Gateway
- Deploy API
- Generate this README.md

---

## 📊 Outcome
- Serverless API: POST /order
- Stores orders in DynamoDB
- Scales automatically with API Gateway + Lambda
EOF

echo "📄 README.md generated."

