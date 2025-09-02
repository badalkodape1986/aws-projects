output "ec2_public_ip" {
  description = "Public IP of the EC2 monitoring instance"
  value       = aws_instance.monitoring_demo.public_ip
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for CloudWatch alarms"
  value       = aws_sns_topic.alerts.arn
}

output "confirmation_instructions" {
  description = "Reminder to confirm SNS subscription"
  value       = "Check your email (${var.alert_email}) and confirm the SNS subscription."
}
