#!/bin/bash
set -e

# -----------------------------
# Inputs
# -----------------------------
DOMAIN_NAME=$1
ZONE_ID=$2
FORCE=$3   # optional --force flag

if [ -z "$DOMAIN_NAME" ] || [ -z "$ZONE_ID" ]; then
  echo "Usage: ./setup-serverless-website.sh <domain_name> <route53_zone_id> [--force]"
  exit 1
fi

PROJECT_DIR="project-3-serverless-website"
mkdir -p $PROJECT_DIR && cd $PROJECT_DIR

echo "🚀 Setting up Serverless Website Hosting for $DOMAIN_NAME"

# -----------------------------
# Helper function
# -----------------------------
create_file() {
  FILE=$1
  CONTENT=$2
  if [ "$FORCE" == "--force" ]; then
    echo "✏️ Overwriting $FILE (--force enabled)"
    echo "$CONTENT" > "$FILE"
  else
    if [ ! -f "$FILE" ]; then
      echo "📄 Creating $FILE"
      echo "$CONTENT" > "$FILE"
    else
      echo "✔️ Skipping $FILE (already exists)"
    fi
  fi
}

# -----------------------------
# Terraform files
# -----------------------------
create_file provider.tf 'provider "aws" {
  region = "us-east-1" # ACM for CloudFront must be in us-east-1
}'

create_file variables.tf 'variable "domain_name" {
  description = "Custom domain name"
  type        = string
}
variable "route53_zone_id" {
  description = "Hosted Zone ID of Route53"
  type        = string
}'

create_file outputs.tf 'output "s3_bucket_name" {
  value = aws_s3_bucket.website.bucket
}
output "cloudfront_domain" {
  value = aws_cloudfront_distribution.cdn.domain_name
}'

create_file s3.tf 'resource "aws_s3_bucket" "website" {
  bucket = var.domain_name
  acl    = "public-read"
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}
resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}'

create_file acm.tf 'resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  subject_alternative_names = ["www.${var.domain_name}"]
}
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}
resource "aws_acm_certificate_validation" "cert_validated" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}'

create_file cloudfront.tf 'resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "s3-origin"
  }
  enabled             = true
  default_root_object = "index.html"
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
  }
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert_validated.certificate_arn
    ssl_support_method  = "sni-only"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  aliases = [var.domain_name, "www.${var.domain_name}"]
}'

create_file route53.tf 'resource "aws_route53_record" "website_alias" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}'

# -----------------------------
# README.md
# -----------------------------
create_file README.md "# Project 3: Serverless Website Hosting with Terraform

This project provisions a **serverless static website** hosted on **Amazon S3**, distributed via **CloudFront**, secured with **HTTPS (ACM)**, and connected to a custom domain via **Route53**.

## Prerequisites
- AWS account with admin access
- Registered domain in Route53
- Terraform installed
- AWS CLI configured

## Steps
1. Run:
   \`\`\`bash
   ./setup-serverless-website.sh <domain_name> <route53_zone_id>
   \`\`\`

   Or, to overwrite Terraform files:
   \`\`\`bash
   ./setup-serverless-website.sh <domain_name> <route53_zone_id> --force
   \`\`\`

2. Upload your website files:
   \`\`\`bash
   aws s3 sync ./website s3://<domain_name> --delete
   \`\`\`

3. Open your browser at:
   - https://<domain_name>

## Cleanup
\`\`\`bash
terraform destroy -auto-approve -var=\"domain_name=<domain>\" -var=\"route53_zone_id=<zone_id>\"
\`\`\`"

# -----------------------------
# Terraform Apply
# -----------------------------
terraform init -input=false
terraform apply -auto-approve \
  -var="domain_name=$DOMAIN_NAME" \
  -var="route53_zone_id=$ZONE_ID"

# -----------------------------
# Website Files
# -----------------------------
mkdir -p website
if [ ! -f website/index.html ]; then
  echo "<h1>Welcome to $DOMAIN_NAME 🚀</h1>" > website/index.html
fi
if [ ! -f website/error.html ]; then
  echo "<h2>Oops! Page not found</h2>" > website/error.html
fi

aws s3 sync ./website s3://$DOMAIN_NAME --delete

echo "🌍 Website deployed successfully at: https://$DOMAIN_NAME"
