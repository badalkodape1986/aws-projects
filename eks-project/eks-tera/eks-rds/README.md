# 📘 Amazon EKS with Custom VPC + RDS (Terraform)

This project provisions:
1. A **Custom VPC** with:
   - 2 Public Subnets (LoadBalancers)
   - 2 Private Subnets (EKS + RDS)
   - IGW + NAT Gateway
2. An **EKS Cluster** in private subnets
3. A **Node Group** (2 nodes, fixed size)
4. A **PostgreSQL RDS Database** (private-only)
5. A **NGINX Deployment** exposed via LoadBalancer

---

## 🔹 Setup

1. Run scaffold script:
   ```bash
   ./eks_with_private_vpc_rds_scaffold.sh

