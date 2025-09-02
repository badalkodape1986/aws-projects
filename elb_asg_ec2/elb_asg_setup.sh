#!/bin/bash
# elb_asg_setup.sh
# Automates setup of Application Load Balancer + Auto Scaling Group (EC2) + generates README.md

set -e

# -------------------------------
# Variables (edit as needed)
# -------------------------------
REGION="ap-south-1"
VPC_ID="<YOUR_VPC_ID>"               # Replace with your VPC ID
SUBNET1="<YOUR_SUBNET1>"             # Replace with subnet in AZ1
SUBNET2="<YOUR_SUBNET2>"             # Replace with subnet in AZ2
KEY_NAME="<YOUR_KEYPAIR>"            # Replace with EC2 Key Pair name
AMI_ID="ami-0dee22c13ea7a9a67"       # Amazon Linux 2 AMI (check for your region)
INSTANCE_TYPE="t2.micro"
SG_NAME="web-sg"
LAUNCH_TEMPLATE_NAME="web-template"
TG_NAME="web-tg"
ALB_NAME="web-alb"
ASG_NAME="web-asg"

# -------------------------------
# Create Security Group
# -------------------------------
echo "🔹 Creating Security Group..."
SG_ID=$(aws ec2 create-security-group \
  --group-name $SG_NAME \
  --description "Allow SSH and HTTP" \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'GroupId' --output text)

# Allow SSH + HTTP
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $REGION
echo "✅ Security Group created: $SG_ID"

# -------------------------------
# Create Launch Template
# -------------------------------
echo "🔹 Creating Launch Template..."
aws ec2 create-launch-template \
  --launch-template-name $LAUNCH_TEMPLATE_NAME \
  --version-description "v1" \
  --launch-template-data "{
    \"ImageId\":\"$AMI_ID\",
    \"InstanceType\":\"$INSTANCE_TYPE\",
    \"KeyName\":\"$KEY_NAME\",
    \"SecurityGroupIds\":[\"$SG_ID\"],
    \"UserData\":\"$(echo '#!/bin/bash
      yum update -y
      yum install -y httpd
      systemctl enable httpd
      systemctl start httpd
      echo Hello from $(hostname) > /var/www/html/index.html' | base64)\"
  }" \
  --region $REGION
echo "✅ Launch Template created: $LAUNCH_TEMPLATE_NAME"

# -------------------------------
# Create Target Group
# -------------------------------
echo "🔹 Creating Target Group..."
TG_ARN=$(aws elbv2 create-target-group \
  --name $TG_NAME \
  --protocol HTTP \
  --port 80 \
  --vpc-id $VPC_ID \
  --target-type instance \
  --region $REGION \
  --query 'TargetGroups[0].TargetGroupArn' --output text)
echo "✅ Target Group created: $TG_ARN"

# -------------------------------
# Create Application Load Balancer
# -------------------------------
echo "🔹 Creating ALB..."
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name $ALB_NAME \
  --subnets $SUBNET1 $SUBNET2 \
  --security-groups $SG_ID \
  --scheme internet-facing \
  --type application \
  --region $REGION \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# Create listener
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN \
  --region $REGION
echo "✅ ALB created: $ALB_ARN"

# -------------------------------
# Create Auto Scaling Group
# -------------------------------
echo "🔹 Creating Auto Scaling Group..."
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name $ASG_NAME \
  --launch-template "LaunchTemplateName=$LAUNCH_TEMPLATE_NAME,Version=1" \
  --min-size 1 \
  --max-size 3 \
  --desired-capacity 2 \
  --vpc-zone-identifier "$SUBNET1,$SUBNET2" \
  --target-group-arns $TG_ARN \
  --health-check-type ELB \
  --region $REGION
echo "✅ Auto Scaling Group created: $ASG_NAME"

# -------------------------------
# Attach Scaling Policies
# -------------------------------
echo "🔹 Creating Scaling Policies..."
ASG_POLICY_OUT=$(aws autoscaling put-scaling-policy \
  --auto-scaling-group-name $ASG_NAME \
  --policy-name scale-out \
  --scaling-adjustment 1 \
  --adjustment-type ChangeInCapacity \
  --region $REGION)

ASG_POLICY_IN=$(aws autoscaling put-scaling-policy \
  --auto-scaling-group-name $ASG_NAME \
  --policy-name scale-in \
  --scaling-adjustment -1 \
  --adjustment-type ChangeInCapacity \
  --region $REGION)
echo "✅ Scaling Policies attached."
