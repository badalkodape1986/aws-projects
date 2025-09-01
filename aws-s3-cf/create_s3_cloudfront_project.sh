#!/bin/bash
# 🚀 Generator: AWS S3 + CloudFront Website Project
# Author: You 😎

set -e
BASE_DIR="02-aws-projects/s3-cloudfront-website"
mkdir -p $BASE_DIR

# ============================
# setup.sh (Bash + AWS CLI)
# ============================
cat > $BASE_DIR/setup.sh <<'EOF'
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
EOF

chmod +x $BASE_DIR/setup.sh

# ============================
# deploy.py (Python + Boto3)
# ============================
cat > $BASE_DIR/deploy.py <<'EOF'
#!/usr/bin/env python3
import boto3, json, sys

bucket = input("Enter S3 bucket name: ")
domain = input("Enter domain name: ")
cert_arn = input("Enter ACM Certificate ARN (must be validated in us-east-1): ")

cf = boto3.client('cloudfront')

print("🚀 Creating CloudFront distribution...")
response = cf.create_distribution(
    DistributionConfig={
        'CallerReference': domain,
        'Comment': f"Static website for {domain}",
        'Enabled': True,
        'Origins': {
            'Quantity': 1,
            'Items': [{
                'Id': bucket,
                'DomainName': f"{bucket}.s3.amazonaws.com",
                'S3OriginConfig': {'OriginAccessIdentity': ''}
            }]
        },
        'DefaultCacheBehavior': {
            'TargetOriginId': bucket,
            'ViewerProtocolPolicy': 'redirect-to-https',
            'AllowedMethods': {'Quantity': 2, 'Items': ['GET', 'HEAD']},
            'CachedMethods': {'Quantity': 2, 'Items': ['GET', 'HEAD']},
            'ForwardedValues': {'QueryString': False, 'Cookies': {'Forward': 'none'}},
            'MinTTL': 0
        },
        'ViewerCertificate': {
            'ACMCertificateArn': cert_arn,
            'SSLSupportMethod': 'sni-only',
            'MinimumProtocolVersion': 'TLSv1.2_2019',
        },
        'Aliases': {'Quantity': 1, 'Items': [domain]},
        'DefaultRootObject': 'index.html'
    }
)

print("✅ CloudFront Distribution Created!")
print("Distribution Domain:", response['Distribution']['DomainName'])
EOF

chmod +x $BASE_DIR/deploy.py

# ============================
# README.md
# ============================
cat > $BASE_DIR/README.md <<'EOF'
# 🌐 AWS S3 + CloudFront Website Project

This project provisions a **serverless static website** using **S3 + CloudFront + ACM**.

---

## 🚀 Features
- S3 Bucket for website hosting
- Public bucket policy
- CloudFront CDN for global caching
- HTTPS via ACM Certificate (us-east-1)
- Deployment automated via AWS CLI & Boto3

---

## 📘 Usage

### 1. Setup Bucket & Certificate
```bash
./setup.sh

