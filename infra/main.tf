# infra/main.tf - Composicao dos modulos

# Data source: AMI Amazon Linux 2023
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ------------------------------------------------------------
# Modulo VPC (base) - subnets publicas e privadas em 2 AZs
# ------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr     = var.vpc_cidr
  project_name = var.project_name
  environment  = var.environment
  subnets      = var.subnets
}

# ------------------------------------------------------------
# Security Group da EC2 (SSH 22 + API 3000)
# Composicao: usa vpc_id do modulo VPC
# ------------------------------------------------------------
module "ec2_sg" {
  source = "./modules/security-group"

  name         = "${var.project_name}-${var.environment}-ec2-sg"
  vpc_id       = module.vpc.vpc_id
  environment  = var.environment
  project_name = var.project_name

  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH"
    },
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "API Node.js"
    }
  ]
}

# ------------------------------------------------------------
# Security Group do RDS (5432 apenas do SG da EC2)
# Composicao: usa vpc_id do modulo VPC
# ------------------------------------------------------------
module "rds_sg" {
  source = "./modules/security-group"

  name         = "${var.project_name}-${var.environment}-rds-sg"
  vpc_id       = module.vpc.vpc_id
  environment  = var.environment
  project_name = var.project_name

  # Menor privilegio: PostgreSQL apenas de dentro da VPC (SG do EC2)
  ingress_rules = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "PostgreSQL da VPC (EC2)"
    }
  ]
}

# ------------------------------------------------------------
# Modulo RDS PostgreSQL - banco da API na nuvem (subnets privadas)
# Composicao: usa subnets privadas do VPC + SG do RDS
# ------------------------------------------------------------
module "database" {
  source = "./modules/rds"

  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.rds_sg.sg_id]
  instance_class     = "db.t3.micro"
  environment        = var.environment
  project_name       = var.project_name
}

# ------------------------------------------------------------
# Modulo EC2 - roda a API de Reservas, conecta no RDS
# Composicao: usa subnet publica do VPC + SG da EC2 + endpoint do RDS
# ------------------------------------------------------------
module "api_server" {
  source = "./modules/ec2"

  instance_name        = "${var.project_name}-${var.environment}-api"
  instance_type        = "t2.micro"
  ami_id               = data.aws_ami.amazon_linux.id
  subnet_id            = module.vpc.public_subnet_ids[0]
  security_group_ids   = [module.ec2_sg.sg_id]
  iam_instance_profile = "LabInstanceProfile"
  environment          = var.environment
  project_name         = var.project_name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    dnf update -y
    dnf install -y nodejs npm git

    mkdir -p /opt/api-reservas
    cd /opt/api-reservas

    # Clona o codigo da API (ajuste a URL do seu repo se necessario)
    # Para o lab, a API tambem pode ser copiada via user_data.
    cat > package.json << 'PKG'
    {
      "name": "api-reservas",
      "version": "1.0.0",
      "main": "server.js",
      "dependencies": { "express": "^4.18.2", "pg": "^8.11.3" }
    }
    PKG

    npm install

    # A API conecta no RDS usando as variaveis de ambiente
    cat > /etc/systemd/system/api-reservas.service << SERVICE
    [Unit]
    Description=API de Reservas
    After=network.target

    [Service]
    Type=simple
    WorkingDirectory=/opt/api-reservas
    Environment=PORT=3000
    Environment=DB_HOST=${module.database.db_endpoint}
    Environment=DB_PORT=5432
    Environment=DB_USER=${var.db_username}
    Environment=DB_NAME=${var.db_name}
    ExecStart=/usr/bin/node server.js
    Restart=always

    [Install]
    WantedBy=multi-user.target
    SERVICE

    echo "Setup do EC2 concluido" >> /var/log/api-setup.log
  EOF
  )
}