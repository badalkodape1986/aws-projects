# 📘 AWS SNS + SQS Fan-out Pattern (Terraform)

This project provisions:
- **SNS Topic**: `OrderPlacedTopic`
- **3 SQS Queues**: `EmailQueue`, `PaymentQueue`, `InventoryQueue`
- Subscriptions from SNS → SQS
- Policies to allow SNS to publish to SQS

---

## 🔹 Setup

1. Update `terraform.tfvars`:
   ```hcl
   region = "ap-south-1"

