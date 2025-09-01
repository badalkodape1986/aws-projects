#!/bin/bash
# 🚀 Generator: Terraform AWS S3 + CloudFront + ACM + Route53 Website Project
# Author: You 😎

set -e
BASE_DIR="terraform/s3-cf-acm-website"
mkdir -p $BASE_DIR

# ============================
# main.tf
# ============================
cat > $BASE_DIR/main.tf <<'EOF'
provider "aws" {
  region = var.region
}

# S3 Bucket for Website
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name
  acl    = "public-read"

  website {
    index_document = var.index_document
    error_document = var.error_document
  }

  tags = {
    Name    = "${var.project_name}-bucket"
    Project = var.project_name
  }
}

# Public Bucket Policy
resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = "*",
      Action    = ["s3:GetObject"],
      Resource  = "${aws_s3_bucket.website.arn}/*"
    }]
  })
}

# ACM Certificate (must be in us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 Record for ACM Validation
resource "aws_route53_record" "cert_validation" {
  name    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type
  zone_id = var.route53_zone_id
  records = [tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

# Validate ACM Certificate
resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "s3-website-origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.index_document

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-website-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = [var.domain_name]

  tags = {
    Name    = "${var.project_name}-cdn"
    Project = var.project_name
  }
}

# Route53 Record for CloudFront
resource "aws_route53_record" "alias" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
EOF

# ============================
# variables.tf
# ============================
cat > $BASE_DIR/variables.tf <<'EOF'
variable "region" {
  description = "AWS region for S3"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "terraform-s3-cloudfront"
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "index_document" {
  description = "Index document for website"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document for website"
  type        = string
  default     = "error.html"
}

variable "domain_name" {
  description = "Custom domain for website (e.g., www.example.com)"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for domain"
  type        = string
}
EOF

# ============================
# outputs.tf
# ============================
cat > $BASE_DIR/outputs.tf <<'EOF'
output "s3_bucket_name" {
  value = aws_s3_bucket.website.bucket
}

output "s3_website_endpoint" {
  value = aws_s3_bucket.website.website_endpoint
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "custom_domain_name" {
  value = var.domain_name
}
EOF

# ============================
# README.md
# ============================
cat > $BASE_DIR/README.md <<'EOF'
# 🌐 Terraform Project: AWS S3 + CloudFront + ACM + Route53 Website Hosting

This project provisions a **serverless static website** using **Amazon S3 + CloudFront + ACM (SSL) + Route53** with Terraform.

---

## 🚀 Features
- S3 Bucket for static website hosting
- Public bucket policy for file access
- CloudFront CDN for global caching
- HTTPS via ACM certificate (auto-validated in Route53)
- Custom domain mapped via Route53 alias record

---

## 📘 Usage

### 1. Navigate to the project folder
```bash
cd terraform/s3-cf-acm-website

