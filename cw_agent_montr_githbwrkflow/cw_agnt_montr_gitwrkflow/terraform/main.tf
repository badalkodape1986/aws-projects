terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "CloudWatch-Monitoring"
      Environment = terraform.workspace
      Monitoring  = "Enabled"
    }
  }
}
