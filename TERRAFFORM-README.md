# ☁️ AWS Terraform Projects

This section of the repository contains **Terraform projects** to automate AWS infrastructure.  
Terraform is used here to demonstrate **Infrastructure as Code (IaC)** principles for **S3 Backup/Restore** and **S3 Static Website Hosting**.

---

## 📂 Project Structure

terraform/
├── s3-backup-restore/
│ ├── main.tf
│ ├── variables.tf
│ └── outputs.tf
└── s3-static-website/
├── main.tf
├── variables.tf
└── outputs.tf


---

## 🔹 1. S3 Backup & Restore Automation

This project provisions an **S3 bucket for backups** with:
- **Versioning enabled** (keeps old versions of files)
- **Lifecycle rule** (moves objects to Glacier after 30 days, expires after 365 days)
- **Private bucket ACL** (secure by default)

### 🚀 Usage
```bash
cd 02-aws-projects/terraform/s3-backup-restore

# Initialize Terraform
terraform init

# Plan resources
terraform plan

# Apply changes
terraform apply -auto-approve

# Destroy resources when not needed
terraform destroy -auto-approve

📘 Variables

region → AWS region (default: us-east-1)

bucket_name → Name of the backup bucket

📤 Outputs

backup_bucket_name → S3 bucket name

backup_bucket_arn → S3 bucket ARN

🔹 2. S3 Static Website Hosting

This project provisions an S3 bucket for static website hosting with:

Website configuration (index.html & error.html)

Public read policy (so anyone can access)

Terraform-managed bucket policy

🚀 Usage

cd 02-aws-projects/terraform/s3-static-website

# Initialize Terraform
terraform init

# Plan resources
terraform plan

# Apply changes
terraform apply -auto-approve

# Destroy resources when not needed
terraform destroy -auto-approve

📘 Variables

region → AWS region (default: us-east-1)

bucket_name → S3 bucket name

index_document → Index file (default: index.html)

error_document → Error file (default: error.html)

📤 Outputs

website_url → Public website endpoint (e.g. http://<bucket>.s3-website-us-east-1.amazonaws.com)

🎯 Skills Demonstrated

Infrastructure as Code (Terraform)

AWS S3 Automation

Lifecycle rules & object versioning

Website hosting with S3

AWS IAM Policies (public access for website)

⚠️ Notes

Ensure you have configured AWS CLI with valid credentials:

aws configure


Terraform will create real AWS resources → clean up with terraform destroy to avoid costs.


---

# ✅ Why This README is Valuable
- Clear **project purpose** (backup vs website)  
- Easy-to-follow **usage instructions**  
- Lists **variables & outputs** → shows you know Terraform standards  
- Warns about **cleanup to avoid AWS costs** (professional touch)  

---

