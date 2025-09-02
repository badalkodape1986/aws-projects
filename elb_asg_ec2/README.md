# -------------------------------
# Generate README.md
# -------------------------------
cat > README.md <<'EOF'
# 📘 AWS Application Load Balancer + Auto Scaling Group (EC2)

This project creates:
- Security Group
- Launch Template with Apache Web Server
- Target Group
- Application Load Balancer
- Auto Scaling Group (min=1, max=3, desired=2)
- Scaling Policies (CPU-based)

---

## 🔹 Manual Steps (Console)

1. **Create Security Group** → allow SSH(22) + HTTP(80).  
2. **Create Launch Template** with User Data:  
   ```bash
   #!/bin/bash
   yum update -y
   yum install -y httpd
   systemctl enable httpd
   systemctl start httpd
   echo "Hello from $(hostname)" > /var/www/html/index.html

🔹 Test

Get ALB DNS Name:

aws elbv2 describe-load-balancers --names web-alb --query 'LoadBalancers[0].DNSName' --output text --region ap-south-1
