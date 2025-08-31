# ☁️ Terraform AWS RDS Project

This project provisions a **VPC with public & private subnets**, launches a **Bastion EC2** in the public subnet, and deploys a **MySQL RDS instance** in the private subnet.

---

## 🚀 Features
- Custom VPC with Public & Private subnets
- Internet Gateway + Route Table for public subnet
- Bastion EC2 (public subnet) for SSH access
- Security Group rules:
  - Bastion → SSH from anywhere
  - RDS → allow MySQL only from Bastion SG
- RDS MySQL instance (private subnet)
- Outputs → Bastion IP/DNS + RDS Endpoint

---

## 📘 Usage

### 1. Navigate into the project
```bash
cd aws-vpc-rds/terraform/rds-project

