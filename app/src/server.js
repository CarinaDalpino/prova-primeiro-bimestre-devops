// src/server.js
// API de Reservas - CRUD completo persistindo em PostgreSQL.

const express = require("express");
const { pool, init } = require("./db");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// ---------- Health check (usado pelo healthcheck do Compose) ----------
app.get("/health", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({ status: "healthy", db: "connected" });
  } catch (err) {
    res.status(503).json({ status: "unhealthy", db: "disconnected" });
  }
});

// ---------- CREATE: POST /reservas ----------
app.post("/reservas", async (req, res) => {
  const { cliente, data, status } = req.body;

  if (!cliente || !data) {
    return res.status(400).json({ erro: "Os campos 'cliente' e 'data' sao obrigatorios." });
  }

  try {
    const result = await pool.query(
      "INSERT INTO reservas (cliente, data, status) VALUES ($1, $2, $3) RETURNING *",
      [cliente, data, status || "pendente"]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ erro: "Erro ao criar reserva.", detalhe: err.message });
  }
});

// ---------- READ (todas): GET /reservas ----------
app.get("/reservas", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM reservas ORDER BY id");
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ erro: "Erro ao listar reservas.", detalhe: err.message });
  }
});

// ---------- READ (por id): GET /reservas/:id ----------
app.get("/reservas/:id", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM reservas WHERE id = $1", [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ erro: "Reserva nao encontrada." });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ erro: "Erro ao buscar reserva.", detalhe: err.message });
  }
});

// ---------- UPDATE: PUT /reservas/:id ----------
app.put("/reservas/:id", async (req, res) => {
  const { cliente, data, status } = req.body;

  try {
    const existe = await pool.query("SELECT * FROM reservas WHERE id = $1", [req.params.id]);
    if (existe.rows.length === 0) {
      return res.status(404).json({ erro: "Reserva nao encontrada." });
    }

    const atual = existe.rows[0];
    const result = await pool.query(
      "UPDATE reservas SET cliente = $1, data = $2, status = $3 WHERE id = $4 RETURNING *",
      [cliente || atual.cliente, data || atual.data, status || atual.status, req.params.id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ erro: "Erro ao atualizar reserva.", detalhe: err.message });
  }
});

// ---------- DELETE: DELETE /reservas/:id ----------
app.delete("/reservas/:id", async (req, res) => {
  try {
    const result = await pool.query("DELETE FROM reservas WHERE id = $1 RETURNING *", [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ erro: "Reserva nao encontrada." });
    }
    res.json({ mensagem: "Reserva removida com sucesso.", reserva: result.rows[0] });
  } catch (err) {
    res.status(500).json({ erro: "Erro ao remover reserva.", detalhe: err.message });
  }
});

// ---------- Boot: inicializa o banco e sobe o servidor ----------
init()
  .then(() => {
    app.listen(PORT, () => console.log("API de Reservas rodando na porta " + PORT));
  })
  .catch((err) => {
    console.error("Falha ao inicializar o banco:", err.message);
    process.exit(1);
  });