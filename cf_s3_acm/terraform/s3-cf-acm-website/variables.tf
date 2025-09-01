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
