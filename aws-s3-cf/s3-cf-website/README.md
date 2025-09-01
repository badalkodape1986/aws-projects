# 🌐 AWS Project 3: Serverless Website Hosting (S3 + CloudFront + ACM)

This project demonstrates how to host a **static website** on **Amazon S3**, serve it globally using **CloudFront (CDN)**, and secure it with **HTTPS (ACM certificate)**.

---

## 📘 Step-by-Step Guide

### **1. Create an S3 Bucket**
1. Go to **AWS Console → S3 → Create bucket**.
2. Enter a **globally unique bucket name** (e.g., `my-portfolio-site-123`).
3. Choose a region (e.g., `us-east-1`).
4. **Uncheck "Block all public access"** → confirm.
5. Click **Create bucket**.

---

### **2. Enable Static Website Hosting**
1. Open your bucket → **Properties tab**.
2. Scroll to **Static website hosting** → Enable.
3. Configure:
   - **Index document**: `index.html`
   - **Error document**: `error.html`
4. Save changes.
5. Copy the **Website endpoint** (e.g. `http://my-portfolio-site-123.s3-website-us-east-1.amazonaws.com`).

---

### **3. Upload Website Files**
1. Go to the **Objects tab → Upload**.
2. Add your `index.html` and `error.html`.
3. Click **Upload**.

---

### **4. Make Files Public**
1. Go to **Permissions tab → Bucket policy**.
2. Add the following policy (replace `my-portfolio-site-123` with your bucket name):

```json
{
  "Version":"2012-10-17",
  "Statement":[{
    "Sid":"PublicReadGetObject",
    "Effect":"Allow",
    "Principal": "*",
    "Action":["s3:GetObject"],
    "Resource":["arn:aws:s3:::my-portfolio-site-123/*"]
  }]
}

