# 📘 Amazon EKS with Custom VPC (Private + Public Subnets, NAT)

This project provisions:
1. A **Custom VPC** with:
   - 2 Public Subnets (for LoadBalancers)
   - 2 Private Subnets (for Worker Nodes)
   - Internet Gateway (IGW)
   - NAT Gateway
2. An **EKS Cluster** using the private subnets for nodes
3. A **Node Group** (2 nodes, fixed size)
4. A **NGINX Deployment** exposed via LoadBalancer

---

## 🔹 Setup

1. Run the scaffold script:
   ```bash
   ./eks_with_private_vpc_scaffold.sh

