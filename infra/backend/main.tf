# infra/backend/main.tf - Infraestrutura de Remote State (S3 + DynamoDB)

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "random_id" "suffix" {
  byte_length = 4
}

# Bucket S3 para o terraform.tfstate
resource "aws_s3_bucket" "tfstate" {
  bucket = "reservas-tfstate-${random_id.suffix.hex}"

  tags = {
    Name    = "reservas-tfstate"
    Project = "reservas"
    Purpose = "Terraform Remote State"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Tabela DynamoDB para locking
resource "aws_dynamodb_table" "locks" {
  name         = "reservas-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "reservas-terraform-locks"
    Project = "reservas"
    Purpose = "Terraform Remote State"
  }
}

output "s3_bucket_name" {
  description = "Nome do bucket S3 do state"
  value       = aws_s3_bucket.tfstate.bucket
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB de locking"
  value       = aws_dynamodb_table.locks.name
}