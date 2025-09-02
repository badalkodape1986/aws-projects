variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "subnet1" {
  description = "First subnet ID for RDS subnet group"
  type        = string
}

variable "subnet2" {
  description = "Second subnet ID for RDS subnet group"
  type        = string
}

variable "my_ip" {
  description = "Your IP with CIDR for DB access (e.g., 1.2.3.4/32)"
  type        = string
}

variable "email" {
  description = "Email for CloudWatch alarm notifications"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database master password (min 8 chars)"
  type        = string
  sensitive   = true
}

variable "db_identifier" {
  description = "RDS instance identifier"
  type        = string
  default     = "mydb-instance"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "mydb"
}
