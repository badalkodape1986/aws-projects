# 📊 CloudWatch Dynamic Monitoring with Terraform + GitHub Actions

This project automates **CloudWatch monitoring** for EC2 instances with:
- ✅ EC2 instance + CloudWatch Agent (CPU, Memory, Disk)
- ✅ CloudWatch Alarms auto-created/deleted via Lambda + EventBridge
- ✅ SNS Alerts via Email
- ✅ GitHub Actions CI/CD pipeline for Terraform

---

## 🚀 Setup Guide

### 1. Prerequisites
- AWS CLI installed & configured (`aws configure`)
- Terraform installed (>=1.5.0)
- GitHub repo for CI/CD
- IAM user with access to EC2, CloudWatch, SNS, Lambda, IAM

---

### 2. AWS Secrets in GitHub
Go to **GitHub → Repo → Settings → Secrets and variables → Actions → New repository secret**  
Add:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

---

### 3. Deploy Infrastructure

```bash
cd cw_agnt_montr_gitwrkflow/terraform
terraform init
terraform apply
