#!/bin/bash
# 🚀 Generator: Terraform AWS S3 Projects
# Author: You 😎

set -e
BASE_DIR="02-aws-projects/terraform"
mkdir -p $BASE_DIR/s3-backup-restore $BASE_DIR/s3-static-website

# ============================
# 1. S3 Backup & Restore
# ============================
cat > $BASE_DIR/s3-backup-restore/main.tf <<'EOF'
provider "aws" {
  region = var.region
}

# Create S3 bucket for backups
resource "aws_s3_bucket" "backup" {
  bucket = var.bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "move-to-glacier"
    enabled = true

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }

  tags = {
    Project = "S3-Backup"
    Managed = "Terraform"
  }
}
EOF

cat > $BASE_DIR/s3-backup-restore/variables.tf <<'EOF'
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}
EOF

cat > $BASE_DIR/s3-backup-restore/outputs.tf <<'EOF'
output "backup_bucket_name" {
  value = aws_s3_bucket.backup.id
}

output "backup_bucket_arn" {
  value = aws_s3_bucket.backup.arn
}
EOF

# ============================
# 2. S3 Static Website Hosting
# ============================
cat > $BASE_DIR/s3-static-website/main.tf <<'EOF'
provider "aws" {
  region = var.region
}

# Create S3 bucket for static website
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name
  acl    = "public-read"

  website {
    index_document = var.index_document
    error_document = var.error_document
  }

  tags = {
    Project = "S3-StaticWebsite"
    Managed = "Terraform"
  }
}

# Bucket policy to allow public read access
resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}
EOF

cat > $BASE_DIR/s3-static-website/variables.tf <<'EOF'
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 website bucket"
  type        = string
}

variable "index_document" {
  description = "Index document for the website"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document for the website"
  type        = string
  default     = "error.html"
}
EOF

cat > $BASE_DIR/s3-static-website/outputs.tf <<'EOF'
output "website_url" {
  value = aws_s3_bucket.website.website_endpoint
}
EOF

echo "🎉 Terraform AWS S3 projects created successfully at $BASE_DIR/"

