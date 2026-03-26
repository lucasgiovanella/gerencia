import express from "express";
import path from "path";
import { pool } from "./database";

const app = express();
const PORT = Number(process.env.PORT) || 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(import.meta.dir, "..", "public")));

// --- Lançamentos CRUD ---

// Listar todos
app.get("/api/lancamentos", async (_req, res) => {
  try {
    const { rows } = await pool.query("SELECT * FROM lancamento ORDER BY data_lancamento DESC");
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erro ao buscar lançamentos" });
  }
});

// Buscar por ID
app.get("/api/lancamentos/:id", async (req, res) => {
  try {
    const { rows } = await pool.query("SELECT * FROM lancamento WHERE id = $1", [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: "Não encontrado" });
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erro ao buscar lançamento" });
  }
});

// Criar
app.post("/api/lancamentos", async (req, res) => {
  try {
    const { descricao, data_lancamento, valor, tipo_lancamento, situacao } = req.body;
    const { rows } = await pool.query(
      `INSERT INTO lancamento (descricao, data_lancamento, valor, tipo_lancamento, situacao)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [descricao, data_lancamento, valor, tipo_lancamento, situacao || "ativo"]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erro ao criar lançamento" });
  }
});

// Atualizar
app.put("/api/lancamentos/:id", async (req, res) => {
  try {
    const { descricao, data_lancamento, valor, tipo_lancamento, situacao } = req.body;
    const { rows } = await pool.query(
      `UPDATE lancamento SET descricao=$1, data_lancamento=$2, valor=$3, tipo_lancamento=$4, situacao=$5
       WHERE id=$6 RETURNING *`,
      [descricao, data_lancamento, valor, tipo_lancamento, situacao, req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: "Não encontrado" });
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erro ao atualizar lançamento" });
  }
});

// Deletar
app.delete("/api/lancamentos/:id", async (req, res) => {
  try {
    const { rowCount } = await pool.query("DELETE FROM lancamento WHERE id = $1", [req.params.id]);
    if (!rowCount) return res.status(404).json({ error: "Não encontrado" });
    res.json({ message: "Deletado com sucesso" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erro ao deletar lançamento" });
  }
});

app.listen(PORT, () => {
  console.log(`Servidor rodando em http://localhost:${PORT}`);
});
