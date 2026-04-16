import { describe, it, expect } from "bun:test";
import request from "supertest";
import { app } from "../src/server";

describe("02 - Testes de Autenticação e Sessão", () => {
  let cookie: string[] = [];

  it("02 - Não deve autenticar usuário com login vazio", async () => {
    const res = await request(app).post("/api/login").send({ login: "", senha: "123" });
    expect(res.status).toBe(401);
    expect(res.body.error).toBe("Login ou senha inválidos");
  });

  it("03 - Não deve autenticar usuário com senha errada", async () => {
    const res = await request(app).post("/api/login").send({ login: "admin", senha: "senhaerrada" });
    expect(res.status).toBe(401);
  });

  it("04 - Não deve autenticar usuário inexistente", async () => {
    const res = await request(app).post("/api/login").send({ login: "outrousuario", senha: "123" });
    expect(res.status).toBe(401);
  });

  it("05 - Deve autenticar usuário administrador e retornar um cookie de sessão", async () => {
    const res = await request(app).post("/api/login").send({ login: "admin", senha: "admin123" });
    expect(res.status).toBe(200);
    expect(res.body.nome).toBe("Administrador");
    const setCookieVal = res.headers["set-cookie"];
    cookie = Array.isArray(setCookieVal) ? setCookieVal : (setCookieVal ? [setCookieVal] : []);
    expect(cookie.length).toBeGreaterThan(0);
  });

  it("06 - Deve retornar erro 401 ao requisitar dados do próprio usuário (/api/me) sem cookie", async () => {
    const res = await request(app).get("/api/me");
    expect(res.status).toBe(401);
  });

  it("07 - Deve retornar dados do próprio usuário (/api/me) logado usando cookie", async () => {
    const res = await request(app).get("/api/me").set("Cookie", cookie);
    expect(res.status).toBe(200);
    expect(res.body.nome).toBe("Administrador");
  });
});
