# 📘 EKS Cluster with Bastion Host (Terraform)

This project provisions:
- Custom VPC (public + private + NAT)
- Bastion Host (Amazon Linux 2) with **kubectl, awscli, helm, eksctl**
- EKS Cluster with 2 private worker nodes

---

## 🔹 Setup

1. Update `terraform.tfvars`:
   ```hcl
   key_name = "my-keypair"
   my_ip    = "YOUR_IP/32"

