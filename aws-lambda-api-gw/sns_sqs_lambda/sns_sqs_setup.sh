#!/bin/bash
# sns_sqs_setup.sh
# Automates setup of SNS + SQS fan-out pattern and generates README.md

set -e

REGION="ap-south-1"
TOPIC_NAME="OrderPlacedTopic"
QUEUES=("EmailQueue" "PaymentQueue" "InventoryQueue")

echo "🚀 Setting up SNS + SQS fan-out architecture..."

# -------------------------------
# Create SNS Topic
# -------------------------------
echo "🔹 Creating SNS topic..."
TOPIC_ARN=$(aws sns create-topic --name $TOPIC_NAME --region $REGION --query "TopicArn" --output text)
echo "✅ SNS topic created: $TOPIC_ARN"

# -------------------------------
# Create SQS Queues and Subscriptions
# -------------------------------
for QUEUE in "${QUEUES[@]}"; do
  echo "🔹 Creating SQS Queue: $QUEUE"
  QUEUE_URL=$(aws sqs create-queue --queue-name $QUEUE --region $REGION --query "QueueUrl" --output text)
  QUEUE_ARN=$(aws sqs get-queue-attributes --queue-url $QUEUE_URL --attribute-names QueueArn --region $REGION --query "Attributes.QueueArn" --output text)

  echo "🔹 Subscribing $QUEUE to $TOPIC_NAME"
  aws sns subscribe \
    --topic-arn $TOPIC_ARN \
    --protocol sqs \
    --notification-endpoint $QUEUE_ARN \
    --region $REGION \
    >/dev/null

  # Allow SNS to publish to this SQS queue
  POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Id": "SQSPolicy",
  "Statement": [
    {
      "Sid": "AllowSNSPublish",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "$QUEUE_ARN",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "$TOPIC_ARN" }
      }
    }
  ]
}
EOF
)
  aws sqs set-queue-attributes \
    --queue-url $QUEUE_URL \
    --attributes Policy="$POLICY" \
    --region $REGION
  echo "✅ Queue $QUEUE created and subscribed."
done

# -------------------------------
# Publish Test Message
# -------------------------------
echo "🔹 Publishing test message to SNS topic..."
aws sns publish \
  --topic-arn $TOPIC_ARN \
  --message '{"orderId":"12345","product":"Laptop","quantity":1}' \
  --region $REGION
echo "✅ Test message published."

# -------------------------------
# Generate README.md
# -------------------------------
cat > README.md <<EOF
# 📘 AWS SNS + SQS (Fan-out Pattern)

This project sets up:
- An **SNS Topic**: $TOPIC_NAME
- **3 SQS Queues**: EmailQueue, PaymentQueue, InventoryQueue
- Subscriptions from SNS → SQS
- Publishes a sample message

---

## 🔹 Manual Steps (Console)

### Step 1: Create SNS Topic
1. Go to **SNS → Topics → Create topic**
2. Type: **Standard**
3. Name: $TOPIC_NAME

### Step 2: Create SQS Queues
1. Go to **SQS → Create queue**
2. Create:
   - EmailQueue
   - PaymentQueue
   - InventoryQueue

### Step 3: Subscribe Queues to SNS
1. Go to **SNS → $TOPIC_NAME → Subscriptions → Create subscription**
2. Protocol = SQS
3. Endpoint = ARN of each queue
4. Repeat for all 3 queues

### Step 4: Publish a Message
1. Go to **SNS → Publish message**
2. Topic: $TOPIC_NAME
3. Message:
   \`\`\`json
   {
     "orderId": "12345",
     "product": "Laptop",
     "quantity": 1
   }
   \`\`\`
4. Check each SQS queue → all should receive the message.

---

## 🔹 Scripted Setup

Run:
\`\`\`bash
./sns_sqs_setup.sh
\`\`\`

This will:
- Create SNS topic
- Create 3 SQS queues
- Subscribe queues to SNS
- Publish a test message
- Generate this README.md

---

## 📊 Outcome
- **Decoupled architecture**: one producer (SNS) → many consumers (SQS)
- All services receive the same event
- Real-world use case: OrderPlaced → Email, Payment, Inventory services
EOF

echo "📄 README.md generated."
echo "🎉 SNS + SQS setup complete."

