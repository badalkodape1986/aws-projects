variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair for SSH access"
  type        = string
}
