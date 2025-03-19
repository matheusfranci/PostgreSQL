```sql
--
-- Script: Gerenciamento de Roles e Privilégios no PostgreSQL
-- Descrição: Este script fornece exemplos de como listar roles, conceder/revogar privilégios a roles e objetos, criar usuários e roles, e verificar usuários e privilégios.
--
-- Principais Roles Predefinidas do PostgreSQL:
--
-- pg_checkpoint: Permite executar checkpoints.
-- pg_database_owner: Permite realizar todas as operações no banco de dados.
-- pg_execute_server_program: Permite executar programas no servidor.
-- pg_maintain: Permite realizar tarefas de manutenção no banco de dados.
-- pg_monitor: Permite monitorar a atividade do banco de dados.
-- pg_read_all_data: Permite ler todos os dados em todas as tabelas.
-- pg_read_all_settings: Permite ler todas as configurações do servidor.
-- pg_read_all_stats: Permite ler todas as estatísticas do servidor.
-- pg_read_server_files: Permite ler arquivos no servidor.
-- pg_signal_backend: Permite enviar sinais para processos backend.
-- pg_stat_scan_tables: Permite executar estatísticas em tabelas.
-- pg_use_reserved_connections: Permite usar conexões reservadas.
-- pg_write_all_data: Permite escrever dados em todas as tabelas.
-- pg_write_server_files: Permite escrever arquivos no servidor.

--
-- Concedendo e Revogando Acesso a Roles:
--
-- Sintaxe:
-- GRANT nome_da_role TO usuario;
-- REVOKE nome_da_role FROM usuario;
--
-- Exemplo:
-- GRANT pg_read_all_data TO meu_usuario;
-- REVOKE pg_read_all_data FROM meu_usuario;

--
-- Concedendo e Revogando Acesso a Objetos (Tabelas, Views, etc.):
--
-- Sintaxe:
-- GRANT privilegio ON objeto TO usuario;
-- REVOKE privilegio ON objeto FROM usuario;
--
-- Privilégios disponíveis:
-- SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, CREATE, CONNECT, TEMPORARY, EXECUTE, USAGE, SET, ALTER SYSTEM
--
-- Exemplo:
-- GRANT SELECT, INSERT ON minha_tabela TO meu_usuario;
-- REVOKE SELECT, INSERT ON minha_tabela FROM meu_usuario;

--
-- Concedendo Privilégios com Opção de Concessão (WITH GRANT OPTION):
--
-- Sintaxe:
-- GRANT privilegio ON objeto TO usuario WITH GRANT OPTION;
--
-- Descrição: Permite que o usuário que recebeu o privilégio também possa concedê-lo a outros usuários.
--
-- Exemplo:
-- GRANT ALTER SYSTEM ON DATABASE meu_banco TO meu_usuario WITH GRANT OPTION;

--
-- Criação de Usuários e Roles:
--
-- Sintaxe:
-- CREATE USER nome_do_usuario;
-- CREATE ROLE nome_da_role;
--
-- Exemplos:
-- CREATE USER oriondba;
-- CREATE ROLE orionrole;

--
-- Criação de Usuário com Senha:
--
-- Sintaxe:
-- CREATE USER nome_do_usuario WITH PASSWORD 'senha';
--
-- Exemplo:
-- CREATE USER rm WITH PASSWORD 'rm';

--
-- Criação de Usuário com Limite de Tempo:
--
-- Sintaxe:
-- CREATE USER nome_do_usuario WITH PASSWORD 'senha' VALID UNTIL 'data';
--
-- Exemplo:
-- CREATE USER rm WITH PASSWORD 'rm' VALID UNTIL '2024-01-01';

--
-- Listando Usuários e Privilégios:
--
-- Comando:
-- \du
--
-- Descrição: Este comando do psql lista todos os usuários e suas roles/privilégios.
```

**2. Arquivo Markdown (roles_e_privilegios.md):**

```markdown
# Gerenciamento de Roles e Privilégios no PostgreSQL

Este documento fornece exemplos de como gerenciar roles e privilégios em um banco de dados PostgreSQL.

## Roles Predefinidas

O PostgreSQL possui várias roles predefinidas com privilégios específicos. Algumas das principais são:

*   `pg_checkpoint`: Permite executar checkpoints.
*   `pg_database_owner`: Permite realizar todas as operações no banco de dados.
*   `pg_execute_server_program`: Permite executar programas no servidor.
*   `pg_maintain`: Permite realizar tarefas de manutenção no banco de dados.
*   `pg_monitor`: Permite monitorar a atividade do banco de dados.
*   `pg_read_all_data`: Permite ler todos os dados em todas as tabelas.
*   `pg_read_all_settings`: Permite ler todas as configurações do servidor.
*   `pg_read_all_stats`: Permite ler todas as estatísticas do servidor.
*   `pg_read_server_files`: Permite ler arquivos no servidor.
*   `pg_signal_backend`: Permite enviar sinais para processos backend.
*   `pg_stat_scan_tables`: Permite executar estatísticas em tabelas.
*   `pg_use_reserved_connections`: Permite usar conexões reservadas.
*   `pg_write_all_data`: Permite escrever dados em todas as tabelas.
*   `pg_write_server_files`: Permite escrever arquivos no servidor.

## Concedendo e Revogando Acesso a Roles

Para conceder ou revogar acesso a uma role para um usuário, utilize os seguintes comandos:

### Sintaxe

\`\`\`sql
GRANT nome_da_role TO usuario;
REVOKE nome_da_role FROM usuario;
\`\`\`

### Exemplo

\`\`\`sql
GRANT pg_read_all_data TO meu_usuario;
REVOKE pg_read_all_data FROM meu_usuario;
\`\`\`

## Concedendo e Revogando Acesso a Objetos

Para conceder ou revogar acesso a objetos (tabelas, views, etc.), utilize os seguintes comandos:

### Sintaxe

\`\`\`sql
GRANT privilegio ON objeto TO usuario;
REVOKE privilegio ON objeto FROM usuario;
\`\`\`

### Privilégios Disponíveis

Os privilégios disponíveis para conceder ou revogar em objetos são:

*   `SELECT`
*   `INSERT`
*   `UPDATE`
*   `DELETE`
*   `TRUNCATE`
*   `REFERENCES`
*   `TRIGGER`
*   `CREATE`
*   `CONNECT`
*   `TEMPORARY`
*   `EXECUTE`
*   `USAGE`
*   `SET`
*   `ALTER SYSTEM`

### Exemplo

\`\`\`sql
GRANT SELECT, INSERT ON minha_tabela TO meu_usuario;
REVOKE SELECT, INSERT ON minha_tabela FROM meu_usuario;
\`\`\`

## Concedendo Privilégios com Opção de Concessão

Para permitir que um usuário conceda o privilégio que recebeu a outros usuários, utilize a cláusula `WITH GRANT OPTION`:

### Sintaxe

\`\`\`sql
GRANT privilegio ON objeto TO usuario WITH GRANT OPTION;
\`\`\`

### Exemplo

\`\`\`sql
GRANT ALTER SYSTEM ON DATABASE meu_banco TO meu_usuario WITH GRANT OPTION;
\`\`\`

## Criação de Usuários e Roles

Para criar usuários e roles, utilize os seguintes comandos:

### Sintaxe

\`\`\`sql
CREATE USER nome_do_usuario;
CREATE ROLE nome_da_role;
\`\`\`

### Exemplos

\`\`\`sql
CREATE USER oriondba;
CREATE ROLE orionrole;
\`\`\`

## Criação de Usuário com Senha

Para criar um usuário com senha, utilize o seguinte comando:

### Sintaxe

\`\`\`sql
CREATE USER nome_do_usuario WITH PASSWORD 'senha';
\`\`\`

### Exemplo

\`\`\`sql
CREATE USER rm WITH PASSWORD 'rm';
\`\`\`

## Criação de Usuário com Limite de Tempo

Para criar um usuário com um limite de tempo de validade, utilize o seguinte comando:

### Sintaxe

\`\`\`sql
CREATE USER nome_do_usuario WITH PASSWORD 'senha' VALID UNTIL 'data';
\`\`\`

### Exemplo

\`\`\`sql
CREATE USER rm WITH PASSWORD 'rm' VALID UNTIL '2024-01-01';
\`\`\`

## Listando Usuários e Privilégios

Para listar todos os usuários e seus privilégios, utilize o seguinte comando no `psql`:

\`\`\`
\du
\`\`\`
```

**O que foi feito:**

*   **Comentários no SQL:** Adicionei comentários detalhados no script SQL para explicar cada parte do código.
*   **Estrutura Markdown:** Criei um arquivo Markdown com títulos, subtítulos, listas e blocos de código para organizar as informações de forma clara.
*   **Blocos de Código:** Usei blocos de código Markdown para inserir os exemplos de comandos SQL, preservando a formatação.
*   **Explicações Detalhadas:** Adicionei explicações em Markdown para cada seção, incluindo a sintaxe dos comandos, exemplos de uso e o significado de cada elemento.
