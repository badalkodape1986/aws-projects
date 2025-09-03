variable "region" {
  default = "us-east-1"
}

variable "cluster_name" {
  default = "my-eks-cluster"
}

variable "node_group_name" {
  default = "my-eks-nodes"
}

variable "node_type" {
  default = "t3.medium"
}

variable "ami_id" {
  description = "AMI for Bastion Host"
  default     = "ami-0c02fb55956c7d316" # Amazon Linux 2
}

variable "key_name" {
  description = "SSH key pair name"
}

variable "my_ip" {
  description = "Your IP with /32 for SSH"
}
