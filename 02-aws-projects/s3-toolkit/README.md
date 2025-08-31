# ☁️ AWS S3 Toolkit

This project provides an **all-in-one AWS S3 automation script** that handles:

1. **Backup** → Upload files to S3 (with timestamp)  
2. **Restore** → Download the latest backup from S3  
3. **Static Website Hosting** → Host a website on S3 with index & error page  

---

## 🚀 Features
- Simple CLI menu for all operations
- Uses AWS CLI (must be configured with `aws configure`)
- Works with any bucket in your AWS account
- Supports automatic timestamped backups

---

## 📘 Usage

### 1. Run the toolkit
```bash
./aws-s3-toolkit.sh

