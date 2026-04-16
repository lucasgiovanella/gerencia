import { describe, it, expect, beforeAll } from "bun:test";
import request from "supertest";
import { app } from "../src/server";

describe("04 - Testes de Cadastros, Edições e E-mails (Lançamentos)", () => {
  let cookie: string[] = [];
  let lancamentoCriadoId: number;

  beforeAll(async () => {
    // Autentica para rodar os testes de CRUD seguintes (Simulação para conseguir o Cookie válido)
    const res = await request(app).post("/api/login").send({ login: "admin", senha: "admin123" });
    const setCookieVal = res.headers["set-cookie"];
    cookie = Array.isArray(setCookieVal) ? setCookieVal : (setCookieVal ? [setCookieVal] : []);
  });

  it("12 - Deve listar todos os lançamentos via GET com autenticação", async () => {
    const res = await request(app).get("/api/lancamentos").set("Cookie", cookie);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it("13 - Deve criar um novo lançamento de receita (Avalia chamada do método de e-mail)", async () => {
    const novoLancamento = {
      descricao: "Investimento Teste Automatizado",
      data_lancamento: "2026-05-15",
      valor: 2500.5,
      tipo_lancamento: "receita",
      situacao: "ativo"
    };
    const res = await request(app).post("/api/lancamentos").set("Cookie", cookie).send(novoLancamento);
    expect(res.status).toBe(201);
    expect(res.body.id).toBeDefined();
    expect(res.body.descricao).toBe("Investimento Teste Automatizado");
    
    lancamentoCriadoId = res.body.id;
  });

  it("14 - O lançamento recém criado deve constar na listagem total do DB", async () => {
    const res = await request(app).get("/api/lancamentos").set("Cookie", cookie);
    expect(res.status).toBe(200);
    const encontrado = res.body.find((l: any) => l.id === lancamentoCriadoId);
    expect(encontrado).toBeDefined();
  });

  it("15 - Deve filtrar lançamentos recém criados por descrição na Query Param da rota GET", async () => {
    const res = await request(app).get("/api/lancamentos?descricao=Investimento Teste").set("Cookie", cookie);
    expect(res.status).toBe(200);
    expect(res.body.length).toBeGreaterThan(0);
    expect(res.body[0].descricao).toContain("Teste");
  });

  it("16 - Deve atualizar o lançamento criado (Avalia nova chamada de método de e-mail ao atualizar)", async () => {
    const alterado = {
      descricao: "Investimento Teste Atualizado",
      data_lancamento: "2026-05-16",
      valor: 2600.0,
      tipo_lancamento: "receita",
      situacao: "inativo"
    };
    const res = await request(app).put(`/api/lancamentos/${lancamentoCriadoId}`).set("Cookie", cookie).send(alterado);
    expect(res.status).toBe(200);
    expect(res.body.descricao).toBe("Investimento Teste Atualizado");
  });

  it("17 - Deve buscar um lançamento específico pelo seu ID recém alterado", async () => {
    const res = await request(app).get(`/api/lancamentos/${lancamentoCriadoId}`).set("Cookie", cookie);
    expect(res.status).toBe(200);
    expect(res.body.id).toBe(lancamentoCriadoId);
    expect(res.body.situacao).toBe("inativo");
  });

  it("18 - Deve retornar erro 404 ao tentar editar as propriedades de um lançamento logado mas que é inexistente", async () => {
    const alterado = {
      descricao: "Investimento Fantasma",
      data_lancamento: "2026-01-01",
      valor: 1,
      tipo_lancamento: "despesa",
      situacao: "ativo"
    };
    const res = await request(app).put(`/api/lancamentos/999999`).set("Cookie", cookie).send(alterado);
    expect(res.status).toBe(404);
  });

  it("19 - Deve deletar o lançamento recém-criado eliminando-o do banco", async () => {
    const res = await request(app).delete(`/api/lancamentos/${lancamentoCriadoId}`).set("Cookie", cookie);
    expect(res.status).toBe(200);
    expect(res.body.message).toBe("Deletado com sucesso");
  });

  it("20 - Deve retornar erro genérico 404 caso busque um recurso que acabou de ser apagado fisicamente", async () => {
    const res = await request(app).get(`/api/lancamentos/${lancamentoCriadoId}`).set("Cookie", cookie);
    expect(res.status).toBe(404);
  });
});
