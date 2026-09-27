# infra/providers.tf

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend S3 para state remoto (Aula 05).
  # Descomente apos criar o bucket/tabela em infra/backend/ e rode:
  #   terraform init -migrate-state
  #
  # backend "s3" {
  #   bucket         = "reservas-tfstate-SEUSUFIXO"
  #   key            = "prova/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "reservas-terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region
}