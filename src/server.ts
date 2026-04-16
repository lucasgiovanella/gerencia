import express from "express";
import path from "path";
import crypto from "crypto";
import { pool } from "./database";
import { Resend } from "resend";

const app = express();
let resend: Resend | null = null;
if (process.env.RESEND_API_KEY) {
  resend = new Resend(process.env.RESEND_API_KEY);
}

async function sendNotificationEmail(action: "adicionado" | "atualizado", lancamento: any, emailDestino?: string) {
  if (!resend) {
    console.warn("RESEND_API_KEY não configurada. E-mail não será enviado.");
    return;
  }
  
  const receiver = emailDestino || process.env.NOTIFICATION_EMAIL || "lucasgiovanella92@gmail.com";
  
  try {
    await resend.emails.send({
      from: "onboarding@resend.dev",
      to: receiver,
      subject: `Lançamento ${action} - Sistema`,
      html: `<p>Um registro de lançamento foi <strong>${action}</strong>:</p>
             <ul>
               <li><strong>ID:</strong> ${lancamento.id}</li>
               <li><strong>Descrição:</strong> ${lancamento.descricao}</li>
               <li><strong>Valor:</strong> R$ ${Number(lancamento.valor).toFixed(2)}</li>
               <li><strong>Tipo:</strong> ${lancamento.tipo_lancamento}</li>
               <li><strong>Situação:</strong> ${lancamento.situacao}</li>
             </ul>`
    });
  } catch (error) {
    console.error("Erro ao enviar email via Resend:", error);
  }
}
const PORT = Number(process.env.PORT) || 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(import.meta.dirname ?? ".", "..", "public")));

// --- Sessões em memória ---
const sessions = new Map<string, { userId: number; nome: string }>();

function parseCookies(header: string) {
  const cookies: Record<string, string> = {};
  header.split(";").forEach((c) => {
    const [k, v] = c.trim().split("=");
    if (k && v) cookies[k] = v;
  });
  return cookies;
}

// --- Middleware de autenticação ---
function auth(req: express.Request, res: express.Response, next: express.NextFunction) {
  const cookies = parseCookies(req.headers.cookie || "");
  const session = sessions.get(cookies.session_id || "");
  if (!session) return res.status(401).json({ error: "Não autenticado" });
  (req as any).user = session;
  next();
}

// --- Auth routes ---

app.post("/api/login", async (req, res) => {
  try {
    const { login, senha } = req.body;
    const { rows } = await pool.query(
      "SELECT id, nome FROM usuario WHERE login = $1 AND senha = $2 AND situacao = 'ativo'",
      [login, senha]
    );

    if (!rows.length) {
      return res.status(401).json({ error: "Login ou senha inválidos" });
    }

    const sessionId = crypto.randomBytes(32).toString("hex");
    sessions.set(sessionId, { userId: rows[0].id, nome: rows[0].nome });

    res.setHeader("Set-Cookie", `session_id=${sessionId}; Path=/; HttpOnly`);
    res.json({ nome: rows[0].nome });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erro interno" });
  }
});

app.post("/api/logout", (_req, res) => {
  const cookies = parseCookies(_req.headers.cookie || "");
  sessions.delete(cookies.session_id || "");
  res.setHeader("Set-Cookie", "session_id=; Path=/; HttpOnly; Max-Age=0");
  res.json({ message: "Logout realizado" });
});

app.get("/api/me", (req, res) => {
  const cookies = parseCookies(req.headers.cookie || "");
  const session = sessions.get(cookies.session_id || "");
  if (!session) return res.status(401).json({ error: "Não autenticado" });
  res.json(session);
});

// --- Lançamentos CRUD (protegido) ---

app.get("/api/lancamentos", auth, async (req, res) => {
  try {
    const { descricao, data_inicio, data_fim, tipo_lancamento, situacao } = req.query;
    let query = "SELECT * FROM lancamento WHERE 1=1";
    const params: any[] = [];
    let paramCount = 1;

    if (descricao) {
      query += ` AND descricao ILIKE $${paramCount}`;
      params.push(`%${descricao}%`);
      paramCount++;
    }
    if (data_inicio) {
      query += ` AND data_lancamento >= $${paramCount}`;
      params.push(data_inicio as string);
      paramCount++;
    }
    if (data_fim) {
      query += ` AND data_lancamento <= $${paramCount}`;
      params.push(data_fim as string);
      paramCount++;
    }
    if (tipo_lancamento) {
      query += ` AND tipo_lancamento = $${paramCount}`;
      params.push(tipo_lancamento as string);
      paramCount++;
    }
    if (situacao) {
      query += ` AND situacao = $${paramCount}`;
      params.push(situacao as string);
      paramCount++;
    }

    query += " ORDER BY data_lancamento DESC";

    const { rows } = await pool.query(query, params);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erro ao buscar lançamentos" });
  }
});

app.get("/api/lancamentos/:id", auth, async (req, res) => {
  try {
    const { rows } = await pool.query("SELECT * FROM lancamento WHERE id = $1", [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: "Não encontrado" });
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erro ao buscar lançamento" });
  }
});

app.post("/api/lancamentos", auth, async (req, res) => {
  try {
    const { descricao, data_lancamento, valor, tipo_lancamento, situacao, email_notificacao } = req.body;
    const { rows } = await pool.query(
      `INSERT INTO lancamento (descricao, data_lancamento, valor, tipo_lancamento, situacao)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [descricao, data_lancamento, valor, tipo_lancamento, situacao || "ativo"]
    );
    // Envia o e-mail em background sem bloquear a response
    sendNotificationEmail("adicionado", rows[0], email_notificacao);
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erro ao criar lançamento" });
  }
});

app.put("/api/lancamentos/:id", auth, async (req, res) => {
  try {
    const { descricao, data_lancamento, valor, tipo_lancamento, situacao, email_notificacao } = req.body;
    const { rows } = await pool.query(
      `UPDATE lancamento SET descricao=$1, data_lancamento=$2, valor=$3, tipo_lancamento=$4, situacao=$5
       WHERE id=$6 RETURNING *`,
      [descricao, data_lancamento, valor, tipo_lancamento, situacao, req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: "Não encontrado" });
    // Envia o e-mail em background sem bloquear a response
    sendNotificationEmail("atualizado", rows[0], email_notificacao);
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erro ao atualizar lançamento" });
  }
});

app.delete("/api/lancamentos/:id", auth, async (req, res) => {
  try {
    const { rowCount } = await pool.query("DELETE FROM lancamento WHERE id = $1", [req.params.id]);
    if (!rowCount) return res.status(404).json({ error: "Não encontrado" });
    res.json({ message: "Deletado com sucesso" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erro ao deletar lançamento" });
  }
});

if (process.env.NODE_ENV !== "test") {
  app.listen(PORT, () => {
    console.log(`Servidor rodando em http://localhost:${PORT}`);
  });
}

export { app };
