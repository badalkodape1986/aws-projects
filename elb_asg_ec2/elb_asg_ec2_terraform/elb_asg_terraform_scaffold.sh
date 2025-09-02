#!/bin/bash
# elb_asg_terraform_scaffold.sh
# Generates Terraform config for ALB + Auto Scaling Group (EC2) + CloudWatch alarms

set -e

echo "🚀 Generating Terraform project for ALB + Auto Scaling Group with CloudWatch alarms..."

# -------------------------------
# variables.tf
# -------------------------------
cat > variables.tf <<'EOF'
variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet1" {
  description = "Subnet 1"
  type        = string
}

variable "subnet2" {
  description = "Subnet 2"
  type        = string
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
EOF

# -------------------------------
# terraform.tfvars (example values)
# -------------------------------
cat > terraform.tfvars <<'EOF'
region     = "ap-south-1"
vpc_id     = "vpc-1234567890abcdef"
subnet1    = "subnet-abc12345"
subnet2    = "subnet-def67890"
key_name   = "my-keypair"
ami_id     = "ami-0dee22c13ea7a9a67" # replace with correct AMI for your region
instance_type = "t2.micro"
EOF

# -------------------------------
# main.tf
# -------------------------------
cat > main.tf <<'EOF'
provider "aws" {
  region = var.region
}

# -------------------------------
# Security Group
# -------------------------------
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

# -------------------------------
# Launch Template
# -------------------------------
resource "aws_launch_template" "web_template" {
  name_prefix   = "web-template-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode(<<-EOT
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl enable httpd
              systemctl start httpd
              echo "Hello from \$(hostname)" > /var/www/html/index.html
              EOT
  )
}

# -------------------------------
# Target Group
# -------------------------------
resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }
}

# -------------------------------
# Application Load Balancer
# -------------------------------
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [var.subnet1, var.subnet2]

  tags = {
    Name = "web-alb"
  }
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# -------------------------------
# Auto Scaling Group
# -------------------------------
resource "aws_autoscaling_group" "web_asg" {
  name                      = "web-asg"
  vpc_zone_identifier       = [var.subnet1, var.subnet2]
  desired_capacity          = 2
  min_size                  = 1
  max_size                  = 3
  health_check_type         = "EC2"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.web_tg.arn]

  tag {
    key                 = "Name"
    value               = "web-asg-instance"
    propagate_at_launch = true
  }
}

# -------------------------------
# Scaling Policies + CloudWatch Alarms
# -------------------------------
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out-policy"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in-policy"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "CPUHigh-ASG"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  alarm_description = "Scale out if CPU > 70% for 4 minutes"
  alarm_actions     = [aws_autoscaling_policy.scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "CPULow-ASG"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  alarm_description = "Scale in if CPU < 30% for 4 minutes"
  alarm_actions     = [aws_autoscaling_policy.scale_in.arn]
}

# -------------------------------
# Output
# -------------------------------
output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = aws_lb.web_alb.dns_name
}
EOF

# -------------------------------
# README.md
# -------------------------------
cat > README.md <<'EOF'
# 📘 AWS ALB + Auto Scaling Group with CloudWatch Alarms (Terraform)

This project provisions:
- A **Launch Template** with Apache web server
- A **Security Group** (HTTP + SSH)
- A **Target Group**
- An **Application Load Balancer (ALB)**
- An **Auto Scaling Group** (min=1, max=3, desired=2)
- **CloudWatch Alarms** (CPU > 70% → scale out, CPU < 30% → scale in)

---

## 🔹 Setup

1. Update **terraform.tfvars** with your values:
   ```hcl
   region     = "ap-south-1"
   vpc_id     = "vpc-1234567890abcdef"
   subnet1    = "subnet-abc12345"
   subnet2    = "subnet-def67890"
   key_name   = "my-keypair"
   ami_id     = "ami-0dee22c13ea7a9a67"
   instance_type = "t2.micro"

