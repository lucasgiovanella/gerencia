CREATE TABLE IF NOT EXISTS categoria (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    situacao VARCHAR(20) NOT NULL DEFAULT 'ativo'
);

INSERT INTO categoria (nome) VALUES
('Alimentação'),
('Transporte'),
('Salário');
