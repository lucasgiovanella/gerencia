# Documentação — Registro de Despesas e Receitas

## 1. Sobre a Aplicação

Aplicação web para registro e visualização de despesas e receitas, desenvolvida com **TypeScript**, **Bun**, **Express**, **PostgreSQL** e **Docker**.

### 1.1 Estrutura do Projeto (Classes/Módulos)

| Módulo | Arquivo | Descrição |
|---|---|---|
| Servidor | `src/server.ts` | Servidor Express – CRUD de lançamentos e servir frontend |
| Banco de Dados | `src/database.ts` | Pool de conexão PostgreSQL via `pg` |
| Frontend | `public/index.html` | Interface HTML com formulário CRUD e tabela de listagem |
| Init SQL | `init.sql` | DDL das tabelas + seed de dados |

**Total: 2 módulos TypeScript + 1 página HTML + 1 script SQL**

### 1.2 Endpoints da API

| Método | Rota | Descrição |
|---|---|---|
| GET | `/api/lancamentos` | Listar todos os lançamentos |
| GET | `/api/lancamentos/:id` | Buscar lançamento por ID |
| POST | `/api/lancamentos` | Criar novo lançamento |
| PUT | `/api/lancamentos/:id` | Atualizar lançamento |
| DELETE | `/api/lancamentos/:id` | Deletar lançamento |

### 1.3 Modelagem do Banco de Dados

#### Tabela `usuario`

| Coluna | Tipo | Restrições |
|---|---|---|
| id | SERIAL | PRIMARY KEY |
| nome | VARCHAR(100) | NOT NULL |
| login | VARCHAR(50) | NOT NULL, UNIQUE |
| senha | VARCHAR(100) | NOT NULL |
| situacao | VARCHAR(20) | NOT NULL, DEFAULT 'ativo' |

#### Tabela `lancamento`

| Coluna | Tipo | Restrições |
|---|---|---|
| id | SERIAL | PRIMARY KEY |
| descricao | VARCHAR(200) | NOT NULL |
| data_lancamento | DATE | NOT NULL |
| valor | NUMERIC(10,2) | NOT NULL |
| tipo_lancamento | VARCHAR(20) | NOT NULL, CHECK ('receita' ou 'despesa') |
| situacao | VARCHAR(20) | NOT NULL, DEFAULT 'ativo' |

```
┌──────────────────────┐       ┌──────────────────────────┐
│      usuario         │       │       lancamento          │
├──────────────────────┤       ├──────────────────────────┤
│ id          SERIAL   │       │ id              SERIAL   │
│ nome        VARCHAR  │       │ descricao       VARCHAR  │
│ login       VARCHAR  │       │ data_lancamento DATE     │
│ senha       VARCHAR  │       │ valor           NUMERIC  │
│ situacao    VARCHAR  │       │ tipo_lancamento VARCHAR  │
└──────────────────────┘       │ situacao        VARCHAR  │
                               └──────────────────────────┘
```

### 1.4 Interface Desenvolvida

A aplicação possui uma interface web limpa e minimalista contendo:

- **Formulário CRUD**: criar e editar lançamentos diretamente na página.
- **Tabela de lançamentos**: listagem com ID, descrição, data, valor (BRL), tipo e situação.
- **Botões de ação**: editar e excluir em cada linha da tabela.
- Design responsivo para desktop e mobile.

---

## 2. Publicação na VM

### 2.1 Como Acessar a VM

```bash
ssh usuario@<IP_DA_VM>
```

### 2.2 Instalação das Ferramentas

#### Docker e Docker Compose

```bash
# Atualizar pacotes
sudo apt update && sudo apt upgrade -y

# Instalar Docker
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# Instalar Docker Compose (plugin)
sudo apt install -y docker-compose-plugin

# Verificar instalação
docker --version
docker compose version
```

#### Git

```bash
sudo apt install -y git
```

### 2.3 Implantação da Aplicação

```bash
# Clonar o repositório
git clone https://github.com/<SEU_USUARIO>/gerencia.git
cd gerencia

# Subir os containers
docker compose up --build -d

# Verificar se os containers estão rodando
docker compose ps
```

### 2.4 URL de Acesso

```
http://<IP_DA_VM>:3000
```

**Credenciais de acesso ao sistema:**
- Login: `admin`
- Senha: `admin123`

---

## 3. Tempos Gastos

| Etapa | Tempo |
|---|---|
| Desenvolvimento da aplicação | ___ min |
| Criação do ambiente na VM | ___ min |
| Publicação da aplicação | ___ min |
| **Total** | **___ min** |

---

## 4. Como Executar Localmente

### Pré-requisitos

- [Docker](https://www.docker.com/) instalado
- [Docker Compose](https://docs.docker.com/compose/) instalado

### Comandos

```bash
# Subir tudo (PostgreSQL + App)
docker compose up --build -d

# Ver logs
docker compose logs -f app

# Parar
docker compose down

# Parar e apagar dados do banco
docker compose down -v
```

Acesse: **http://localhost:3000**
