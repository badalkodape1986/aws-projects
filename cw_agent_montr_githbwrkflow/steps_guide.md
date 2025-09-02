cw_agnt_montr_gitwrkflow.sh 
Generates all Terraform files (EC2, CloudWatch Agent, SNS, Lambda automation, variables, outputs)

Generates GitHub Actions workflow (terraform.yml)

Generates README.md with clear manual setup steps (GitHub-style)

# 🚀 CloudWatch Agent + Terraform + GitHub Actions CI/CD

This project is scaffolded by `cw_agnt_montr_gitwrkflow.sh`.

It sets up:
- **Terraform project** with EC2, CloudWatch Agent, Alarms (CPU, Memory, Disk), SNS, Lambda automation
- **GitHub Actions workflow** (`terraform.yml`) for CI/CD
- **README.md** with manual setup instructions

---

## ✅ What this Script Does

- Creates **Terraform project** with:
  - EC2 + CloudWatch Agent
  - CloudWatch Alarms (CPU / Memory / Disk)
  - SNS Alerts
  - Lambda + EventBridge automation
- Creates **GitHub Actions workflow** for CI/CD
- Creates **README.md** with setup instructions  

---

## 📦 Project Structure

terraform-project/
├── main.tf
├── variables.tf
├── outputs.tf
├── lambda_function.py
├── lambda.zip # packaged by helper script
└── .github/workflows/terraform.yml


---

## 🔧 Setup Steps

### 1. Generate Project Scaffold
Run the script:

```bash
bash cw_agnt_montr_gitwrkflow.sh

You should see:

✅ Project scaffold created in <BASE_DIR>

2. Initialize Terraform

Inside the generated project:

terraform init
terraform validate

3. Configure Variables

Edit variables.tf and set your values (especially alert_email).

4. Confirm SNS Subscription

After first apply:

Check your email (alert_email)

Confirm subscription

Without confirmation → ❌ no alerts will arrive

5. GitHub Actions CI/CD

Pull Request (PR) → runs terraform plan (safe preview, no infra changes)

Merge to main → runs terraform apply (infra deployed/updated automatically)

Workflow file: .github/workflows/terraform.yml

6. Package Lambda Function (Required Step)

Terraform expects a .zip file for deploying the Lambda.
Run this helper before terraform apply:

# inside terraform-project directory
zip lambda.zip lambda_function.py


✅ This will create lambda.zip that Terraform uses in deployment.

ℹ️ You need to re-run this step whenever you change lambda_function.py.

7. Test Alarms

SSH into EC2:

ssh -i your-key.pem ec2-user@<public-ip>


Generate CPU load:

yes > /dev/null &


Generate Memory load:

stress-ng --vm 1 --vm-bytes 90% --timeout 120s


Generate Disk usage:

fallocate -l 2G /tmp/testfile


✅ CloudWatch alarms will trigger → SNS → Email alert 🚨

8. Cleanup

Destroy all resources:

terraform destroy


This will remove:

EC2

CloudWatch Alarms

Lambda

EventBridge

SNS
