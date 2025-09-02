# 🧪 Testing the Serverless Order API

This document explains how to test the deployed **Serverless Order API** and verify that it correctly stores orders in **DynamoDB**.

---

## ▶️ Test the API

Run the following `curl` command to place an order:

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"product":"Laptop","quantity":1}' \
  $(terraform output -raw api_url)


🔹 Expected Response
{
  "message": "Order placed successfully",
  "orderId": "<uuid>"
}


message → Confirms the order was processed.

orderId → A unique identifier (UUID) for the newly created order.
