// src/db.js
// Conexao com PostgreSQL usando pg (Pool).
// As credenciais vem de variaveis de ambiente (definidas no .env / docker-compose / RDS).
// SSL e ativado via DB_SSL=true (necessario para o RDS; nao usado no Postgres local).

const { Pool } = require("pg");

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "postgres",
  database: process.env.DB_NAME || "reservas",
  ssl: process.env.DB_SSL === "true" ? { rejectUnauthorized: false } : false
});

// Cria a tabela reservas se ainda nao existir (executado no boot da API)
async function init() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS reservas (
      id SERIAL PRIMARY KEY,
      cliente VARCHAR(120) NOT NULL,
      data VARCHAR(60) NOT NULL,
      status VARCHAR(40) NOT NULL DEFAULT 'pendente'
    );
  `);
}

module.exports = { pool, init };