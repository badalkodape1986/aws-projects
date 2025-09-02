# 📘 Amazon EKS + RDS + Node.js App (Terraform)

This project provisions:
- Custom **VPC** (Public + Private + IGW + NAT)
- **EKS Cluster** with private worker nodes
- **PostgreSQL RDS** (private-only)
- **Node.js App** (connects to RDS via Secrets)
- **LoadBalancer Service** exposing the app

---

## 🔹 Setup

1. Build & push your Node.js Docker image:
   ```bash
   docker build -t node-postgres-app .
   docker tag node-postgres-app:latest <your-dockerhub>/node-postgres-app:latest
   docker push <your-dockerhub>/node-postgres-app:latest

