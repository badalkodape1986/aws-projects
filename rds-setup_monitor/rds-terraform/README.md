# 📘 AWS RDS (MySQL) + CloudWatch Alarm via Terraform

This project provisions:
- An **RDS MySQL database**
- A **Security Group** allowing MySQL access
- An **SNS Topic** with email subscription
- A **CloudWatch Alarm** (CPUUtilization > 70%)

---

## 🔹 Setup

1. Edit **terraform.tfvars** with your values:
   ```hcl
   region      = "ap-south-1"
   vpc_id      = "vpc-1234567890abcdef"
   subnet1     = "subnet-abc12345"
   subnet2     = "subnet-def67890"
   my_ip       = "1.2.3.4/32"
   email       = "you@example.com"
   db_username = "admin"
   db_password = "ChangeMe123!"
   db_identifier = "mydb-instance"
   db_name       = "mydb"

