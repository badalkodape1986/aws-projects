# 📘 Amazon EKS with Custom VPC (Terraform)

This project provisions:
1. A **Custom VPC** with 2 public subnets + IGW
2. An **EKS Cluster** inside the VPC
3. A **Node Group** (2 nodes)
4. A **NGINX Deployment** with LoadBalancer service

---

## 🔹 Setup

1. Generate files:
   ```bash
   ./eks_with_vpc_scaffold.sh

