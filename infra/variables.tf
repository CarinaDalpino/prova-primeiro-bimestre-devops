# infra/variables.tf

variable "aws_region" {
  description = "Regiao AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "reservas"
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnets" {
  description = "Mapa de subnets (cidr, az, type)"
  type = map(object({
    cidr = string
    az   = string
    type = string
  }))
  default = {
    "public-1"  = { cidr = "10.0.1.0/24", az = "us-east-1a", type = "public" }
    "public-2"  = { cidr = "10.0.2.0/24", az = "us-east-1b", type = "public" }
    "private-1" = { cidr = "10.0.3.0/24", az = "us-east-1a", type = "private" }
    "private-2" = { cidr = "10.0.4.0/24", az = "us-east-1b", type = "private" }
  }
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "reservas"
}

variable "db_username" {
  description = "Usuario master do RDS"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Senha master do RDS"
  type        = string
  sensitive   = true
}