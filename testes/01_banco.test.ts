import { describe, it, expect, afterAll } from "bun:test";
import { pool } from "../src/database";

describe("01 - Testes de Banco de Dados", () => {


  it("01 - Deve conectar com o banco de dados (SELECT 1)", async () => {
    const res = await pool.query("SELECT 1 as result");
    expect(res.rows[0].result).toBe(1);
  });
});
