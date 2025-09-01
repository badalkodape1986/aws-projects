#!/bin/bash
# 🚀 Setup Static Website Hosting on S3 + CloudFront
# Prerequisites: AWS CLI configured, domain verified in Route53 for ACM

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -ne "${YELLOW}Enter bucket name (must be globally unique): ${NC}"
read BUCKET
echo -ne "${YELLOW}Enter domain name (must match Route53 record, e.g. example.com): ${NC}"
read DOMAIN

# 1. Create S3 bucket
echo "📦 Creating S3 bucket: $BUCKET"
aws s3 mb s3://$BUCKET

# 2. Enable static website hosting
aws s3 website s3://$BUCKET/ --index-document index.html --error-document error.html

# 3. Make objects public
cat > bucket-policy.json <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[{
    "Sid":"PublicReadGetObject",
    "Effect":"Allow",
    "Principal": "*",
    "Action":["s3:GetObject"],
    "Resource":["arn:aws:s3:::$BUCKET/*"]
  }]
}
POLICY

aws s3api put-bucket-policy --bucket $BUCKET --policy file://bucket-policy.json
rm bucket-policy.json

# 4. Request ACM Certificate (in us-east-1 for CloudFront)
echo "🔒 Requesting ACM Certificate for $DOMAIN"
CERT_ARN=$(aws acm request-certificate \
  --domain-name $DOMAIN \
  --validation-method DNS \
  --region us-east-1 \
  --query "CertificateArn" --output text)

echo "✅ Certificate requested: $CERT_ARN"
echo "⚠️ Please validate domain in Route53, then create CloudFront manually or via deploy.py"
