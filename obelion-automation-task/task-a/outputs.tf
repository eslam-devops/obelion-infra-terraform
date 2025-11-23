# Backend Instance Outputs
output "backend_instance_id" {
  description = "Backend EC2 instance ID"
  value       = aws_instance.backend.id
}

output "backend_instance_public_ip" {
  description = "Backend EC2 instance public IP"
  value       = aws_instance.backend.public_ip
}

output "backend_instance_private_ip" {
  description = "Backend EC2 instance private IP"
  value       = aws_instance.backend.private_ip
}

# Frontend Instance Outputs
output "frontend_instance_id" {
  description = "Frontend EC2 instance ID"
  value       = aws_instance.frontend.id
}

output "frontend_instance_public_ip" {
  description = "Frontend EC2 instance public IP"
  value       = aws_instance.frontend.public_ip
}

output "frontend_instance_private_ip" {
  description = "Frontend EC2 instance private IP"
  value       = aws_instance.frontend.private_ip
}

# RDS MySQL Outputs
output "rds_endpoint" {
  description = "RDS MySQL endpoint address"
  value       = aws_db_instance.mysql.endpoint
}

output "rds_address" {
  description = "RDS MySQL address"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "RDS MySQL port"
  value       = aws_db_instance.mysql.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.mysql.db_name
}

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.obelion.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}

# Security Group Outputs
output "ec2_security_group_id" {
  description = "EC2 security group ID"
  value       = aws_security_group.ec2.id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}
