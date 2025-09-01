# 🌐 S3 + CloudFront Website Deployment

This project demonstrates how to deploy a **static website** on AWS using **S3, Route 53, ACM, and CloudFront**.

---

## 🚀 1. Create S3 Bucket

- Creates an S3 bucket
- Enables **static website hosting**
- Uploads website content

---

## 🔒 2. Request ACM Certificate

- Requests an **SSL/TLS certificate** in ACM
- ⚠️ **Important:** You must validate the certificate in **Route53** (DNS validation) before deploying CloudFront.

---

## 🌍 3. Deploy CloudFront Distribution

Run the deployment script:

```bash
python3 deploy.py

