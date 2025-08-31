# ☁️ Terraform AWS VPC Project

This project provisions a **custom VPC with public subnet** and launches an **EC2 instance with Nginx**.

---

## 🚀 Features
- Creates VPC with CIDR block (default: 10.0.0.0/16)
- Creates a public Subnet (default: 10.0.1.0/24)
- Internet Gateway + Route Table with default route
- Security Group with SSH (22) + HTTP (80)
- EC2 instance inside subnet (with Nginx auto-installed)

---

## 📘 Usage

### 1. Navigate into the project
```bash
cd aws-vpc-terraform/terraform/vpc-project

