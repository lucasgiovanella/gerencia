## Learned User Preferences

- Responder sempre em português.
- Preferência por scripts de setup enxutos na VM, sem instalação de pacotes do sistema ou do Docker no `setup-vm.sh`.
- Erros de formatação Biome para demo devem ser de estilo comum (indentação, aspas, espaços), não `debugger`.

## Learned Workspace Facts

- VM de deploy Univates (VMLS109) em `177.44.248.109`; diretório manual do projeto na VM: `/home/univates/gerencia`.
- Homologação na porta 3001, produção na porta 3002.
- Push em `develop` faz deploy em homolog; push em `main` faz deploy em produção.
- Runner self-hosted na VM, instalado como usuário `univates` em `~/actions-runner`; `config.sh` sem sudo, `svc.sh install` com sudo.
- Jobs de deploy rodam em `${{ github.workspace }}`; runner não tem permissão em `/home/univates/gerencia`.
- `scripts/reset-vm.sh` e `scripts/setup-vm.sh`; reset via `curl | bash` exige `CONFIRM_RESET=RESETAR`.
- Biome (CI) tem passos separados de lint e format; verifica apenas `src/` (`public/` e `testes/` ignorados no `biome.json`).
- Migrações Flyway em `db/migrations/` com padrão `V{n}__nome.sql` (dois underscores).
- CI Flyway usa `docker run redgate/flyway:10` (action `red-gate/setup-flyway@v3` falha com 403).
- Compose de homolog e prod são projetos Docker separados (`gerencia-homolog` / `gerencia-prod`).
- `APRESENTACAO.md` na raiz é a colinha de apresentação (arquitetura, CI/CD, roteiro da demo).
