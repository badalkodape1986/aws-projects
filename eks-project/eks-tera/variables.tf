variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
  default     = "my-eks-cluster"
}

variable "node_group_name" {
  description = "EKS Node Group name"
  type        = string
  default     = "my-eks-nodes"
}

variable "node_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}
