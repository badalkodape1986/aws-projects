#!/bin/bash
# 🚀 AWS VPC Toolkit (Create VPC, Subnet, IGW, EC2)

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

create_vpc() {
  echo -ne "${YELLOW}Enter CIDR block for VPC (e.g. 10.0.0.0/16): ${NC}"
  read CIDR
  VPC_ID=$(aws ec2 create-vpc --cidr-block $CIDR --query 'Vpc.VpcId' --output text)
  aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support '{"Value":true}'
  aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames '{"Value":true}'
  echo -e "${GREEN}✅ VPC Created: $VPC_ID${NC}"
}

create_subnet() {
  echo -ne "${YELLOW}Enter VPC ID: ${NC}"
  read VPC_ID
  echo -ne "${YELLOW}Enter Subnet CIDR (e.g. 10.0.1.0/24): ${NC}"
  read SUBNET_CIDR
  SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_CIDR --query 'Subnet.SubnetId' --output text)
  echo -e "${GREEN}✅ Subnet Created: $SUBNET_ID${NC}"
}

create_igw() {
  echo -ne "${YELLOW}Enter VPC ID: ${NC}"
  read VPC_ID
  IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
  aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
  echo -e "${GREEN}✅ Internet Gateway Attached: $IGW_ID${NC}"
}

create_route_table() {
  echo -ne "${YELLOW}Enter VPC ID: ${NC}"
  read VPC_ID
  echo -ne "${YELLOW}Enter Subnet ID: ${NC}"
  read SUBNET_ID
  RTB_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
  aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $(aws ec2 describe-internet-gateways --query 'InternetGateways[0].InternetGatewayId' --output text)
  aws ec2 associate-route-table --subnet-id $SUBNET_ID --route-table-id $RTB_ID
  echo -e "${GREEN}✅ Route Table Created & Associated: $RTB_ID${NC}"
}

launch_ec2_in_vpc() {
  echo -ne "${YELLOW}Enter Subnet ID: ${NC}"
  read SUBNET_ID
  echo -ne "${YELLOW}Enter Key Pair Name: ${NC}"
  read KEY
  echo -ne "${YELLOW}Enter AMI ID (e.g. ami-08c40ec9ead489470): ${NC}"
  read AMI

  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI \
    --count 1 \
    --instance-type t2.micro \
    --key-name $KEY \
    --subnet-id $SUBNET_ID \
    --associate-public-ip-address \
    --query "Instances[0].InstanceId" \
    --output text)

  echo -e "${GREEN}✅ EC2 Launched in VPC: $INSTANCE_ID${NC}"
}

while true; do
  echo -e "\n${GREEN}=== AWS VPC Toolkit ===${NC}"
  echo "1) Create VPC"
  echo "2) Create Subnet"
  echo "3) Create Internet Gateway"
  echo "4) Create Route Table"
  echo "5) Launch EC2 in VPC"
  echo "6) Quit"
  echo -ne "${YELLOW}Choose an option: ${NC}"
  read choice

  case $choice in
    1) create_vpc ;;
    2) create_subnet ;;
    3) create_igw ;;
    4) create_route_table ;;
    5) launch_ec2_in_vpc ;;
    6) echo "👋 Exiting Toolkit..."; exit 0 ;;
    *) echo -e "${RED}Invalid choice. Try again.${NC}" ;;
  esac
done
