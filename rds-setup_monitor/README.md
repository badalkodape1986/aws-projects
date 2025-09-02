# -------------------------------
# Generate README.md
# -------------------------------
cat > README.md <<'EOF'
# 📘 AWS RDS (MySQL) Setup with CloudWatch Alarm

This project creates a **MySQL RDS instance** manually and via script, with an integrated **CloudWatch Alarm** for CPU monitoring.

---

## 🔹 Manual Steps (Console)

### Step 1: Open RDS Service
- Go to **AWS Console → RDS → Create Database**.

### Step 2: Choose Database Creation Method
- Select **Standard Create**.

### Step 3: Select Engine
- Choose **MySQL** (latest version).

### Step 4: Choose Template
- For learning: **Free tier**  
- For production: **Production**

### Step 5: Configure Settings
- DB instance identifier: `mydb-instance`  
- Master username: `admin`  
- Master password: `********`

### Step 6: Instance Configuration
- For free tier: `db.t3.micro`

### Step 7: Storage
- 20 GB General Purpose SSD

### Step 8: Connectivity
- VPC: your existing VPC  
- Subnet group: select multiple AZs  
- Public access: Yes (for testing)  
- Security Group: allow inbound on port `3306`

### Step 9: Additional Configurations
- Initial DB name: `mydb`  
- Backup retention: 7 days  
- Monitoring: enable Enhanced Monitoring

### Step 10: Launch
- Click **Create database**

### Step 11: Connect to Database
```bash
mysql -h <endpoint> -u admin -p


SHOW DATABASES;

./rds_mysql_setup.sh
