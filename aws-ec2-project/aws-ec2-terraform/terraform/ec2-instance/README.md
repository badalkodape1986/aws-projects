# ☁️ Terraform AWS EC2 Project

This project provisions an **EC2 instance on AWS** using Terraform.

---

## 🚀 Features
- Creates a Security Group with **SSH (22)** and **HTTP (80)** access
- Launches an EC2 instance with a chosen **AMI**, **instance type**, and **key pair**
- Installs **Nginx automatically** using `user_data`
- Outputs EC2 **ID, Public IP, and DNS**

---

## 📘 Usage

### 1. Navigate into the project
```bash
cd aws-ec2-projects/terraform/ec2-instance

