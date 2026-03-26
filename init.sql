-- Criação das tabelas

CREATE TABLE IF NOT EXISTS usuario (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    login VARCHAR(50) NOT NULL UNIQUE,
    senha VARCHAR(100) NOT NULL,
    situacao VARCHAR(20) NOT NULL DEFAULT 'ativo'
);

CREATE TABLE IF NOT EXISTS lancamento (
    id SERIAL PRIMARY KEY,
    descricao VARCHAR(200) NOT NULL,
    data_lancamento DATE NOT NULL,
    valor NUMERIC(10, 2) NOT NULL,
    tipo_lancamento VARCHAR(20) NOT NULL CHECK (tipo_lancamento IN ('receita', 'despesa')),
    situacao VARCHAR(20) NOT NULL DEFAULT 'ativo'
);

-- Seed: 1 usuário

INSERT INTO usuario (nome, login, senha, situacao) VALUES
('Administrador', 'admin', 'admin123', 'ativo');

-- Seed: 10 lançamentos

INSERT INTO lancamento (descricao, data_lancamento, valor, tipo_lancamento, situacao) VALUES
('Salário mensal',          '2026-03-01', 5500.00, 'receita', 'ativo'),
('Aluguel apartamento',     '2026-03-05', 1200.00, 'despesa', 'ativo'),
('Freelance design',        '2026-03-07',  800.00, 'receita', 'ativo'),
('Conta de luz',            '2026-03-10',  210.50, 'despesa', 'ativo'),
('Conta de internet',       '2026-03-10',  119.90, 'despesa', 'ativo'),
('Supermercado',            '2026-03-12',  650.00, 'despesa', 'ativo'),
('Venda de equipamento',    '2026-03-15', 1500.00, 'receita', 'ativo'),
('Combustível',             '2026-03-18',  280.00, 'despesa', 'ativo'),
('Rendimento investimento', '2026-03-20',  320.75, 'receita', 'ativo'),
('Manutenção veículo',      '2026-03-22',  450.00, 'despesa', 'ativo');
