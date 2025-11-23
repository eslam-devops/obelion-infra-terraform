# Outputs - المخرجاات المهمة

# Frontend Public IP
output "frontend_public_ip" {
  description = "Frontend EC2 instance public IP address"
  value       = aws_instance.frontend.public_ip
}

# Backend Public IP
output "backend_public_ip" {
  description = "Backend EC2 instance public IP address"
  value       = aws_instance.backend.public_ip
}

# RDS Database Endpoint
output "rds_endpoint" {
  description = "RDS MySQL database endpoint"
  value       = aws_db_instance.main.endpoint
}

# RDS Database Name
output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}

# VPC ID
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

# Public Subnet ID
output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

# Private Subnet ID  
output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}
