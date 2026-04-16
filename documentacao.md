# Documentação — Registro de Despesas e Receitas

## 1. Sobre a Aplicação

Aplicação web para registro e visualização de despesas e receitas, desenvolvida com **TypeScript**, **Bun**, **Express**, **PostgreSQL** e **Docker**.

### 1.1 Estrutura do Projeto (Classes/Módulos)

| Módulo         | Arquivo             | Descrição                                             |
| -------------- | ------------------- | ----------------------------------------------------- |
| Servidor       | `src/server.ts`     | Servidor Express – autenticação + CRUD de lançamentos |
| Banco de Dados | `src/database.ts`   | Pool de conexão PostgreSQL via `pg`                   |
| Login          | `public/index.html` | Tela de login                                         |
| App            | `public/app.html`   | Interface CRUD de lançamentos (protegida por login)   |
| Init SQL       | `init.sql`          | DDL das tabelas + seed de dados                       |

**Total: 2 módulos TypeScript + 2 páginas HTML + 1 script SQL**

### 1.2 Endpoints da API

| Método | Rota                   | Descrição                   |
| ------ | ---------------------- | --------------------------- |
| POST   | `/api/login`           | Autenticar usuário          |
| POST   | `/api/logout`          | Encerrar sessão             |
| GET    | `/api/me`              | Verificar sessão atual      |
| GET    | `/api/lancamentos`     | Listar todos os lançamentos |
| GET    | `/api/lancamentos/:id` | Buscar lançamento por ID    |
| POST   | `/api/lancamentos`     | Criar novo lançamento       |
| PUT    | `/api/lancamentos/:id` | Atualizar lançamento        |
| DELETE | `/api/lancamentos/:id` | Deletar lançamento          |

> **Nota:** Todas as rotas de `/api/lancamentos` exigem autenticação.

### 1.3 Modelagem do Banco de Dados

#### Tabela `usuario`

| Coluna   | Tipo         | Restrições                |
| -------- | ------------ | ------------------------- |
| id       | SERIAL       | PRIMARY KEY               |
| nome     | VARCHAR(100) | NOT NULL                  |
| login    | VARCHAR(50)  | NOT NULL, UNIQUE          |
| senha    | VARCHAR(100) | NOT NULL                  |
| situacao | VARCHAR(20)  | NOT NULL, DEFAULT 'ativo' |

#### Tabela `lancamento`

| Coluna          | Tipo          | Restrições                               |
| --------------- | ------------- | ---------------------------------------- |
| id              | SERIAL        | PRIMARY KEY                              |
| descricao       | VARCHAR(200)  | NOT NULL                                 |
| data_lancamento | DATE          | NOT NULL                                 |
| valor           | NUMERIC(10,2) | NOT NULL                                 |
| tipo_lancamento | VARCHAR(20)   | NOT NULL, CHECK ('receita' ou 'despesa') |
| situacao        | VARCHAR(20)   | NOT NULL, DEFAULT 'ativo'                |

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

A aplicação possui duas telas:

1. **Tela de login** (`/`) — campos de login e senha, redireciona para a área principal ao autenticar.
2. **Tela principal** (`/app.html`) — exibe nome do usuário logado, formulário para criar/editar lançamentos, tabela com listagem e botões de editar/excluir, e botão de logout.

### 1.5 Novas Funcionalidades (Updates Recentes)

1. **Notificações automáticas por E-mail:** Integração direta com a API da **Resend**. A plataforma dispara e-mails automáticos ao salvar e atualizar Lançamentos (com parâmetros de design). O destinatário é totalmente flexível pois pode ser definido na própria interface web, caindo na API em `req.body.email_notificacao`.
2. **Filtro de Despesas Avançado:** Componentes de input nativos incorporados à UX que alimentam requisições inteligentes (`GET /api/lancamentos?descricao=...`). O sistema varre o PostgreSQL instantaneamente fazendo bind via `ILIKE`.
3. **Exportação Modular para PDF:** Exporta perfeitamente os dados contidos na respectiva filtragem em PDF formatado no paradigma profissional de tabelamento através das bibliotecas dinâmicas cliente-side `jsPDF` e `jsPDF-AutoTable`.

---

## 2. Publicação na VM

### 2.1 Como Acessar a VM

```bash
ssh lucas@177.44.248.109
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
git clone git@github.com:lucasgiovanella/gerencia.git
cd gerencia

# Subir os containers
docker compose up --build -d

# Verificar se os containers estão rodando
docker compose ps
```

### 2.4 URL de Acesso

```
http://177.44.248.109/:3000
```

**Credenciais de acesso ao sistema:**

- Login: `admin`
- Senha: `admin123`

---

## 3. Tempos Gastos

| Etapa                        | Tempo       |
| ---------------------------- | ----------- |
| Desenvolvimento da aplicação | 60 min      |
| Criação do ambiente na VM    | 30 min      |
| Publicação da aplicação      | 30 min      |
| **Total**                    | **120 min** |

## 4. Estrutura do Projeto

```
gerencia/
├── docker-compose.yml
├── Dockerfile
├── init.sql
├── package.json
├── tsconfig.json
├── documentacao.md
├── public/
│   ├── index.html        # Tela de login
│   └── app.html          # Tela principal (CRUD c/ filtros e gerador PDF)
├── src/
│   ├── database.ts        # Conexão com PostgreSQL
│   └── server.ts          # Servidor Express (Auth, Filtros e integração E-mail)
└── testes/
    ├── 01_banco.test.ts          # Testes de Conexão com a pool do Postgres (SELECT 1)
    ├── 02_autenticacao.test.ts   # Testes focados no bloqueio de login e injeção de Sessão
    ├── 03_seguranca.test.ts      # Testes de Proteção de Rotas (Inibir 401 via Middlewares)
    └── 04_lancamentos.test.ts    # Testes base de CRUD (Criação, Edição, Acionamento Backend Email e Remoção em cascata)
```

---

## 5. Como Executar Localmente

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

Acesse: **http://177.44.248.109:3000** localmente em **http://localhost:3000** → faça login com `admin` / `admin123`.

---

## 6. Como Executar os Testes Automatizados (TDD)

O projeto baseia-se na novíssima engine iterativa **`bun:test`** combinada com o **`supertest`** para injetar requisições web reais por debaixo dos panos mapeando todo o roteamento do back-end. A suíte divide-se em **4 arquivos totalizando 20 verificações estritas**.

1. Garanta que o contêiner de banco de dados e o do servidor estejam onlines rodando juntos via processo padrão (`docker compose up -d`).
2. Conecte-se iterativamente ao contêiner da sua aplicação executora:
   ```bash
   docker exec -it gerencia_app bash
   ```
3. Digite o escopo e observe o resultado verde validando a integridade inteira:
   ```bash
   bun test
   ```

*(A API validará a consistência da abstração do Express, forçará as rotas injetando Headers de Cookie temporários, e criará dados fakes para testar os formulários que se apagam sozinhos no decorrer dos 20 testes finalizando isenta de dados acumulativos).*
