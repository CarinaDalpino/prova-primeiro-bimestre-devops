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
  # O bucket e a tabela DynamoDB sao criados primeiro (ver infra/backend/).
  # No Learner Lab, a SCP bloqueia a criacao do bucket via Terraform (object lock),
  # entao o bucket foi criado via AWS CLI com versionamento, encriptacao e block public access.
  # Depois de criar o backend, descomente o bloco abaixo com o nome real do bucket e rode:
  #   terraform init -migrate-state
  #
  # backend "s3" {
  #   bucket         = "reservas-tfstate-XXXXXXXX"
  #   key            = "prova/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "reservas-terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region
}