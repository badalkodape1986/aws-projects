output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_public_dns" {
  value = aws_instance.bastion.public_dns
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}
