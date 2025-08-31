variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "terraform-ec2"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance (Amazon Linux/Ubuntu)"
  type        = string
  default     = "ami-08c40ec9ead489470" # Ubuntu 22.04 LTS in us-east-1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of an existing AWS key pair"
  type        = string
}
