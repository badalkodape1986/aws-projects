#!/bin/bash
# 🚀 Generator: Terraform AWS S3 + CloudFront Website Project
# Author: You 😎

set -e
BASE_DIR="terraform/s3-cloudfront-website"
mkdir -p $BASE_DIR

# ============================
# main.tf
# ============================
cat > $BASE_DIR/main.tf <<'EOF'
provider "aws" {
  region = var.region
}

# S3 Bucket for Static Website
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

# Public Access Policy for S3
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
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name    = "${var.project_name}-cdn"
    Project = var.project_name
  }
}
EOF

# ============================
# variables.tf
# ============================
cat > $BASE_DIR/variables.tf <<'EOF'
variable "region" {
  description = "AWS region"
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
EOF

# ============================
# README.md
# ============================
cat > $BASE_DIR/README.md <<'EOF'
# 🌐 Terraform Project: AWS S3 + CloudFront Website Hosting

This project provisions a **serverless static website** using **Amazon S3 + CloudFront** with Terraform.

---

## 🚀 Features
- S3 Bucket for static website hosting
- Public bucket policy for file access
- CloudFront CDN for global caching
- Redirects HTTP → HTTPS
- Outputs S3 endpoint + CloudFront domain

---

## 📘 Usage

### 1. Navigate to the project folder
```bash
cd terraform/s3-cloudfront-website


