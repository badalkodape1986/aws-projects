#!/bin/bash
# rds_mysql_setup.sh
# Automates RDS MySQL setup + generates README.md with manual steps + CloudWatch Alarm.

set -e

# -------------------------------
# Variables (edit as needed)
# -------------------------------
DB_INSTANCE_ID="mydb-instance"
DB_ENGINE="mysql"
DB_ENGINE_VERSION="8.0.35"
DB_CLASS="db.t3.micro"
DB_STORAGE=20
MASTER_USERNAME="admin"
MASTER_PASSWORD="ChangeMe123!"
DB_NAME="mydb"
VPC_SECURITY_GROUP_ID="<YOUR_SG_ID>"   # Replace with your SG ID that allows 3306
SUBNET_GROUP_NAME="<YOUR_SUBNET_GROUP>" # Replace with your DB subnet group name
REGION="ap-south-1"
ALARM_NAME="HighCPUAlarm-${DB_INSTANCE_ID}"
ALARM_TOPIC_NAME="rds-alarm-topic"

# -------------------------------
# Create RDS Instance
# -------------------------------
echo "🚀 Creating RDS instance: $DB_INSTANCE_ID ..."
aws rds create-db-instance \
  --db-instance-identifier "$DB_INSTANCE_ID" \
  --engine "$DB_ENGINE" \
  --engine-version "$DB_ENGINE_VERSION" \
  --db-instance-class "$DB_CLASS" \
  --allocated-storage "$DB_STORAGE" \
  --master-username "$MASTER_USERNAME" \
  --master-user-password "$MASTER_PASSWORD" \
  --db-name "$DB_NAME" \
  --vpc-security-group-ids "$VPC_SECURITY_GROUP_ID" \
  --db-subnet-group-name "$SUBNET_GROUP_NAME" \
  --publicly-accessible \
  --backup-retention-period 7 \
  --region "$REGION"

echo "⏳ Waiting for DB instance to become available..."
aws rds wait db-instance-available --db-instance-identifier "$DB_INSTANCE_ID" --region "$REGION"

# Get endpoint
ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "$DB_INSTANCE_ID" \
  --region "$REGION" \
  --query "DBInstances[0].Endpoint.Address" --output text)

echo "✅ RDS Instance created successfully!"
echo "   Endpoint: $ENDPOINT"

# -------------------------------
# Setup SNS Topic for Alarm Notifications
# -------------------------------
echo "📡 Creating SNS topic for CloudWatch alarm notifications..."
TOPIC_ARN=$(aws sns create-topic --name "$ALARM_TOPIC_NAME" --region "$REGION" --query "TopicArn" --output text)

echo "📬 Subscribe your email to SNS topic..."
aws sns subscribe --topic-arn "$TOPIC_ARN" --protocol email --notification-endpoint "<YOUR_EMAIL>" --region "$REGION"

echo "⚠️ Please check your email and confirm SNS subscription before alarm triggers."

# -------------------------------
# Create CloudWatch Alarm
# -------------------------------
echo "📊 Creating CloudWatch alarm for CPUUtilization > 70%..."
aws cloudwatch put-metric-alarm \
  --alarm-name "$ALARM_NAME" \
  --metric-name CPUUtilization \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 70 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=DBInstanceIdentifier,Value="$DB_INSTANCE_ID" \
  --evaluation-periods 2 \
  --alarm-actions "$TOPIC_ARN" \
  --region "$REGION"

echo "✅ CloudWatch Alarm created: $ALARM_NAME"
