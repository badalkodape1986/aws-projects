# 📘 Serverless Order API (Terraform)

This project provisions:
- **DynamoDB Table**: `Orders`
- **Lambda Function**: `OrderFunction`
- **API Gateway**: `/order` endpoint (POST)

---

## 🔹 Setup

1. Update **terraform.tfvars**:
   ```hcl
   region = "ap-south-1"

