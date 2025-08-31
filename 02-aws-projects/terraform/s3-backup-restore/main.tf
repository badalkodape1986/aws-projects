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
