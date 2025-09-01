# 🌐 Terraform Project: AWS S3 + CloudFront + ACM + Route53 Website Hosting

This project provisions a **serverless static website** using **Amazon S3 + CloudFront + ACM (SSL) + Route53** with Terraform.

---

## 🚀 Features
- S3 Bucket for static website hosting
- Public bucket policy for file access
- CloudFront CDN for global caching
- HTTPS via ACM certificate (auto-validated in Route53)
- Custom domain mapped via Route53 alias record

---

## 📘 Usage

### 1. Navigate to the project folder
```bash
cd terraform/s3-cf-acm-website

