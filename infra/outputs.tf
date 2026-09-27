# infra/outputs.tf

output "vpc_id" {
  description = "ID da VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs das subnets publicas"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = module.vpc.private_subnet_ids
}

output "ec2_sg_id" {
  description = "ID do Security Group da EC2"
  value       = module.ec2_sg.sg_id
}

output "rds_sg_id" {
  description = "ID do Security Group do RDS"
  value       = module.rds_sg.sg_id
}

output "ec2_public_ip" {
  description = "IP publico da EC2 (API)"
  value       = module.api_server.public_ip
}

output "api_url" {
  description = "URL da API de Reservas"
  value       = "http://${module.api_server.public_ip}:3000"
}

output "rds_endpoint" {
  description = "Endpoint do RDS PostgreSQL"
  value       = module.database.db_endpoint
}