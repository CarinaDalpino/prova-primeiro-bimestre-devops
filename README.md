# Prova do Primeiro Bimestre - DevOps | API de Reservas

**Aluno:** Carina Goncalves dos Santos Dalpino
**RA:** 6325109
**Disciplina:** DevOps - Centro Universitario UniFAAT
**Professor:** Alexandre da Costa Tavares Jr
**Semestre:** 2026-2

## Descricao do Projeto

API de Reservas da TechNova - projeto integrador que reune todas as competencias
do primeiro bimestre (Aulas 01 a 07):

- **Git** - versionamento com Conventional Commits e feature branches
- **Docker** - aplicacao containerizada (Dockerfile multi-stage, usuario nao-root)
- **Docker Compose** - ambiente local (API + PostgreSQL) subindo com um comando
- **Terraform** - infraestrutura AWS modularizada (VPC, Security Group, EC2, RDS)
- **Remote State** - backend S3 + DynamoDB para locking
- **IA como copiloto** - uso documentado no relatorio.md

A aplicacao e uma API Node.js/Express que gerencia reservas (id, cliente, data,
status) com CRUD completo, persistindo os dados em PostgreSQL.

## Rotas da API

| Metodo | Rota | Descricao |
|--------|------|-----------|
| POST | /reservas | Cria uma nova reserva |
| GET | /reservas | Lista todas as reservas |
| GET | /reservas/:id | Busca uma reserva pelo id |
| PUT | /reservas/:id | Atualiza uma reserva |
| DELETE | /reservas/:id | Remove uma reserva |
| GET | /health | Health check |

## Estrutura do Repositorio

```
prova-primeiro-bimestre-devops/
├── app/                  # API de Reservas (Node.js + Express)
├── docker-compose.yml    # API + PostgreSQL (ambiente local)
├── infra/                # Terraform modularizado + backend remoto
├── evidencias/           # Outputs de build, compose e terraform
└── relatorio.md          # Relatorio do processo com IA
```

## Como Rodar Localmente

```bash
cp .env.example .env
docker compose up -d
curl http://localhost:3000/health
```

## Como Provisionar na AWS

Ver instrucoes detalhadas em `infra/` (backend primeiro, depois o projeto principal).