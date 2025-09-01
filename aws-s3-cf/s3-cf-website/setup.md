# 🌐 Securing AWS S3 Website with CloudFront + ACM + Route53

After hosting your static website on **Amazon S3**, the next step is to make it **secure, global, and fast** using **CloudFront CDN** and **HTTPS with ACM certificates**.

---

## ✅ Prerequisite
- Your static website is already hosted on **S3** and publicly accessible.
- You own a domain in **Route53** (e.g., `example.com`).
- AWS CLI or AWS Console access.

---

## 📘 Step-by-Step Guide

### ✅ Your website is now accessible via the S3 website endpoint
Example:  
http://my-portfolio-site-123.s3-website-us-east-1.amazonaws.com


But this URL is **not secure (HTTP)** and not production-friendly.
Let’s fix that with **SSL + CloudFront**.

---

### **5. Request an SSL Certificate (ACM)**
⚠️ CloudFront requires ACM certificates in **`us-east-1`**.

1. Go to **AWS Console → Certificate Manager (ACM)**.
2. Click **Request a certificate** → choose **Public certificate**.
3. Enter your domain (e.g., `www.example.com`).
4. Choose **DNS Validation**.
5. ACM will generate a **CNAME record**.
6. Go to **Route53 → Hosted Zone → example.com → Add Record**.
7. Add the CNAME provided by ACM.
8. Wait until ACM shows status = **Issued**.

---

### **6. Create a CloudFront Distribution**
1. Go to **AWS Console → CloudFront → Create Distribution**.
2. **Origin Domain Name** → your S3 website endpoint.
3. **Viewer protocol policy** → Redirect HTTP → HTTPS.
4. **Alternate domain name (CNAME)** → `www.example.com`.
5. **SSL certificate** → Select the ACM certificate you created.
6. Click **Create Distribution**.

⚡ Deployment may take **10–20 minutes**.

---

### **7. Point Domain to CloudFront**
1. Go to **Route53 → Hosted Zones → example.com**.
2. Create a new **A record (alias)**:
   - **Name**: `www`
   - **Alias target**: Select your CloudFront distribution
3. Save record.

---

### **8. Test Your Website**
- Open `https://www.example.com` in your browser.
- ✅ Website loads from **CloudFront CDN** (fast & global).
- ✅ HTTPS is enabled via **ACM certificate**.

---

## 🎯 Skills Demonstrated
- ACM Certificate provisioning & DNS validation
- CloudFront CDN integration with S3
- HTTPS enforcement (Redirect HTTP → HTTPS)
- Route53 domain mapping
- End-to-end secure serverless web hosting

---

## ✅ Repo Value
This section demonstrates **Cloud Security + CDN Integration** skills that are highly valued in DevOps & Cloud roles.
- Secure global delivery of S3 websites
- Enterprise-grade HTTPS setup
- Practical real-world architecture

