import { describe, it, expect } from "bun:test";
import request from "supertest";
import { app } from "../src/server";

describe("03 - Testes de Segurança e Proteção de Rotas", () => {
  it("08 - Deve bloquear rota GET /api/lancamentos sem autenticação", async () => {
    const res = await request(app).get("/api/lancamentos");
    expect(res.status).toBe(401);
  });

  it("09 - Deve bloquear rota POST /api/lancamentos sem autenticação", async () => {
    const res = await request(app).post("/api/lancamentos").send({});
    expect(res.status).toBe(401);
  });

  it("10 - Deve bloquear rota PUT /api/lancamentos/:id sem autenticação", async () => {
    const res = await request(app).put("/api/lancamentos/1").send({});
    expect(res.status).toBe(401);
  });

  it("11 - Deve bloquear rota DELETE /api/lancamentos/:id sem autenticação", async () => {
    const res = await request(app).delete("/api/lancamentos/1");
    expect(res.status).toBe(401);
  });
});
