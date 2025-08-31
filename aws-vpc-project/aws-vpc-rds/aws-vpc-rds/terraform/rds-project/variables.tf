variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "terraform-rds"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.1.2.0/24"
}

variable "ami_id" {
  description = "AMI ID for Bastion EC2"
  type        = string
  default     = "ami-08c40ec9ead489470" # Ubuntu 22.04 LTS us-east-1
}

variable "instance_type" {
  description = "EC2 instance type for Bastion"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
}

variable "db_username" {
  description = "RDS DB username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "RDS DB password"
  type        = string
  sensitive   = true
}
