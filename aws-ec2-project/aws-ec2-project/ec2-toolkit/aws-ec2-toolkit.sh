#!/bin/bash
# 🚀 AWS EC2 Toolkit (Launch, Start, Stop, Terminate)
# Requires AWS CLI configured with credentials

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

launch_ec2() {
  echo -ne "${YELLOW}Enter AMI ID (e.g. ami-12345678): ${NC}"
  read AMI
  echo -ne "${YELLOW}Enter Instance Type (e.g. t2.micro): ${NC}"
  read TYPE
  echo -ne "${YELLOW}Enter Key Pair Name: ${NC}"
  read KEY
  echo -ne "${YELLOW}Enter Security Group Name: ${NC}"
  read SG

  echo "🌐 Creating Security Group..."
  aws ec2 create-security-group --group-name $SG --description "EC2 Toolkit SG" >/dev/null 2>&1 || true
  aws ec2 authorize-security-group-ingress --group-name $SG --protocol tcp --port 22 --cidr 0.0.0.0/0 >/dev/null 2>&1 || true

  echo "🚀 Launching EC2 Instance..."
  INSTANCE=$(aws ec2 run-instances \
    --image-id $AMI \
    --count 1 \
    --instance-type $TYPE \
    --key-name $KEY \
    --security-groups $SG \
    --query "Instances[0].InstanceId" \
    --output text)

  echo -e "${GREEN}✅ EC2 Instance Launched: $INSTANCE${NC}"
}

list_ec2() {
  echo "📋 Listing running EC2 instances..."
  aws ec2 describe-instances \
    --query "Reservations[].Instances[].[InstanceId,InstanceType,State.Name,PublicIpAddress]" \
    --output table
}

start_ec2() {
  echo -ne "${YELLOW}Enter Instance ID to start: ${NC}"
  read INSTANCE
  aws ec2 start-instances --instance-ids $INSTANCE
  echo -e "${GREEN}✅ EC2 Instance $INSTANCE started${NC}"
}

stop_ec2() {
  echo -ne "${YELLOW}Enter Instance ID to stop: ${NC}"
  read INSTANCE
  aws ec2 stop-instances --instance-ids $INSTANCE
  echo -e "${GREEN}✅ EC2 Instance $INSTANCE stopped${NC}"
}

terminate_ec2() {
  echo -ne "${YELLOW}Enter Instance ID to terminate: ${NC}"
  read INSTANCE
  aws ec2 terminate-instances --instance-ids $INSTANCE
  echo -e "${GREEN}✅ EC2 Instance $INSTANCE terminated${NC}"
}

while true; do
  echo -e "\n${GREEN}=== AWS EC2 Toolkit ===${NC}"
  echo "1) Launch EC2 Instance"
  echo "2) List EC2 Instances"
  echo "3) Start EC2 Instance"
  echo "4) Stop EC2 Instance"
  echo "5) Terminate EC2 Instance"
  echo "6) Quit"
  echo -ne "${YELLOW}Choose an option: ${NC}"
  read choice

  case $choice in
    1) launch_ec2 ;;
    2) list_ec2 ;;
    3) start_ec2 ;;
    4) stop_ec2 ;;
    5) terminate_ec2 ;;
    6) echo "👋 Exiting Toolkit..."; exit 0 ;;
    *) echo -e "${RED}Invalid choice. Try again.${NC}" ;;
  esac
done
