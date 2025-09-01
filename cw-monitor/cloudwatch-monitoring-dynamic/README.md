# 📊 AWS Project 4 (Advanced): Dynamic CloudWatch Monitoring & Alerts

This project automates **CloudWatch monitoring** for **all EC2 instances** using **Lambda + EventBridge + SNS + Terraform**.

✅ Features:
- Automatically create **CPU, Memory, and Disk alarms** when new EC2 instances are launched.  
- Create alarms for **existing EC2** instances (one-time scan).  
- Automatically **delete alarms** when EC2 instances are stopped or terminated.  
- Send alerts via **SNS Email/SMS**.  

---

## 🚀 Deployment

### 1. Package Lambda
```bash
cd cloudwatch-monitoring-dynamic/terraform
zip lambda_monitor.zip ../lambda_monitor.py
