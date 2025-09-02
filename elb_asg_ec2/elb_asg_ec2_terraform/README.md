# 📘 AWS ALB + Auto Scaling Group with CloudWatch Alarms (Terraform)

This project provisions:
- A **Launch Template** with Apache web server
- A **Security Group** (HTTP + SSH)
- A **Target Group**
- An **Application Load Balancer (ALB)**
- An **Auto Scaling Group** (min=1, max=3, desired=2)
- **CloudWatch Alarms** (CPU > 70% → scale out, CPU < 30% → scale in)

---

## 🔹 Setup

1. Update **terraform.tfvars** with your values:
   ```hcl
   region     = "ap-south-1"
   vpc_id     = "vpc-1234567890abcdef"
   subnet1    = "subnet-abc12345"
   subnet2    = "subnet-def67890"
   key_name   = "my-keypair"
   ami_id     = "ami-0dee22c13ea7a9a67"
   instance_type = "t2.micro"

