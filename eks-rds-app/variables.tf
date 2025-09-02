variable "region" { default = "us-east-1" }
variable "cluster_name" { default = "my-eks-cluster" }
variable "node_group_name" { default = "my-eks-nodes" }
variable "node_type" { default = "t3.medium" }
variable "db_username" { type = string }
variable "db_password" { type = string sensitive = true }
