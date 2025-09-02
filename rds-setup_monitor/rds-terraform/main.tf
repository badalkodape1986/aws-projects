provider "aws" {
  region = var.region
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow MySQL access"
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [var.subnet1, var.subnet2]

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_db_instance" "mydb" {
  identifier             = var.db_identifier
  engine                 = "mysql"
  engine_version         = "8.0.35"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = true
  backup_retention_period = 7
  multi_az               = false

  tags = {
    Name = var.db_identifier
  }
}

resource "aws_sns_topic" "rds_alarm_topic" {
  name = "rds-alarm-topic"
}

resource "aws_sns_topic_subscription" "rds_alarm_email" {
  topic_arn = aws_sns_topic.rds_alarm_topic.arn
  protocol  = "email"
  endpoint  = var.email
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "HighCPUAlarm-${var.db_identifier}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mydb.id
  }

  alarm_description = "Alarm when RDS CPU > 70%"
  alarm_actions     = [aws_sns_topic.rds_alarm_topic.arn]
}
