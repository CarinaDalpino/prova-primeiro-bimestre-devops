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
# Security Group do RDS (5432 apenas de dentro da VPC / EC2)
# Composicao: usa vpc_id do modulo VPC
# ------------------------------------------------------------
module "rds_sg" {
  source = "./modules/security-group"

  name         = "${var.project_name}-${var.environment}-rds-sg"
  vpc_id       = module.vpc.vpc_id
  environment  = var.environment
  project_name = var.project_name

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
  key_name             = "reservas-key"
  environment          = var.environment
  project_name         = var.project_name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    dnf install -y nodejs npm

    mkdir -p /opt/api-reservas/src
    cd /opt/api-reservas

    cat > package.json << 'PKG'
    {
      "name": "api-reservas",
      "version": "1.0.0",
      "main": "src/server.js",
      "dependencies": { "express": "^4.18.2", "pg": "^8.11.3" }
    }
    PKG

    cat > src/db.js << 'DBJS'
    const { Pool } = require("pg");
    const pool = new Pool({
      host: process.env.DB_HOST,
      port: process.env.DB_PORT || 5432,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      ssl: { rejectUnauthorized: false }
    });
    async function init() {
      await pool.query(`CREATE TABLE IF NOT EXISTS reservas (
        id SERIAL PRIMARY KEY,
        cliente VARCHAR(120) NOT NULL,
        data VARCHAR(60) NOT NULL,
        status VARCHAR(40) NOT NULL DEFAULT 'pendente'
      );`);
    }
    module.exports = { pool, init };
    DBJS

    cat > src/server.js << 'SRVJS'
    const express = require("express");
    const { pool, init } = require("./db");
    const app = express();
    const PORT = process.env.PORT || 3000;
    app.use(express.json());
    app.get("/health", async (req, res) => {
      try { await pool.query("SELECT 1"); res.json({ status: "healthy", db: "connected" }); }
      catch (e) { res.status(503).json({ status: "unhealthy" }); }
    });
    app.post("/reservas", async (req, res) => {
      const { cliente, data, status } = req.body;
      if (!cliente || !data) return res.status(400).json({ erro: "cliente e data sao obrigatorios" });
      const r = await pool.query("INSERT INTO reservas (cliente,data,status) VALUES ($1,$2,$3) RETURNING *", [cliente, data, status || "pendente"]);
      res.status(201).json(r.rows[0]);
    });
    app.get("/reservas", async (req, res) => {
      const r = await pool.query("SELECT * FROM reservas ORDER BY id");
      res.json(r.rows);
    });
    app.get("/reservas/:id", async (req, res) => {
      const r = await pool.query("SELECT * FROM reservas WHERE id=$1", [req.params.id]);
      if (r.rows.length === 0) return res.status(404).json({ erro: "nao encontrada" });
      res.json(r.rows[0]);
    });
    app.put("/reservas/:id", async (req, res) => {
      const { cliente, data, status } = req.body;
      const e = await pool.query("SELECT * FROM reservas WHERE id=$1", [req.params.id]);
      if (e.rows.length === 0) return res.status(404).json({ erro: "nao encontrada" });
      const a = e.rows[0];
      const r = await pool.query("UPDATE reservas SET cliente=$1,data=$2,status=$3 WHERE id=$4 RETURNING *", [cliente||a.cliente, data||a.data, status||a.status, req.params.id]);
      res.json(r.rows[0]);
    });
    app.delete("/reservas/:id", async (req, res) => {
      const r = await pool.query("DELETE FROM reservas WHERE id=$1 RETURNING *", [req.params.id]);
      if (r.rows.length === 0) return res.status(404).json({ erro: "nao encontrada" });
      res.json({ mensagem: "removida", reserva: r.rows[0] });
    });
    init().then(() => app.listen(PORT, () => console.log("API na porta " + PORT)))
      .catch(e => { console.error(e.message); process.exit(1); });
    SRVJS

    npm install

    cat > /etc/systemd/system/api-reservas.service << 'SERVICE'
    [Unit]
    Description=API de Reservas
    After=network.target
    [Service]
    Type=simple
    WorkingDirectory=/opt/api-reservas
    Environment=PORT=3000
    Environment=DB_HOST=${module.database.db_address}
    Environment=DB_PORT=5432
    Environment=DB_USER=${var.db_username}
    Environment=DB_PASSWORD=${var.db_password}
    Environment=DB_NAME=${var.db_name}
    ExecStart=/usr/bin/node src/server.js
    Restart=always
    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable api-reservas
    systemctl start api-reservas
    echo "Setup do EC2 concluido" >> /var/log/api-setup.log
  EOF
  )
}