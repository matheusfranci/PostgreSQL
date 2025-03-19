Perfeito, vamos refatorar e converter esse script para Markdown.

**1. Script SQL Refatorado (com comentários):**

```sql
--
-- Script: Remoção Completa de Usuário e Privilégios no PostgreSQL
-- Descrição: Este script remove um usuário específico e revoga todos os seus privilégios no banco de dados, schemas, sequences e tabelas.
--
-- Passo 1: Revogar Privilégios no Nível do Banco de Dados
--
-- Comando:
-- REVOKE ALL ON DATABASE nome_do_banco FROM nome_do_usuario;
--
-- Descrição: Revoga todos os privilégios do usuário no banco de dados especificado.
--
REVOKE ALL ON DATABASE database_dummy FROM user_dummy;

--
-- Passo 2: Gerar Comandos para Revogar Privilégios em Schemas, Sequences e Tabelas
--
-- Descrição: As consultas abaixo geram comandos SQL para revogar todos os privilégios do usuário em todos os schemas, sequences e tabelas, exceto os schemas padrão (information_schema, pg_catalog, public).
--
-- Comandos Gerados:
-- REVOKE ALL PRIVILEGES ON SCHEMA nome_do_schema FROM nome_do_usuario;
-- REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA nome_do_schema FROM nome_do_usuario;
-- REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA nome_do_schema FROM nome_do_usuario;
--
-- Consulta para Schemas:
SELECT 'REVOKE ALL PRIVILEGES ON SCHEMA ' || schema_name || ' FROM user_dummy;'
FROM information_schema.schemata
WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'public')
UNION ALL
-- Consulta para Sequences:
SELECT 'REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ' || schema_name || ' FROM user_dummy;'
FROM information_schema.schemata
WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'public')
UNION ALL
-- Consulta para Tabelas:
SELECT 'REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA ' || schema_name || ' FROM user_dummy;'
FROM information_schema.schemata
WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'public');

--
-- Passo 3: Remover o Usuário
--
-- Comando:
-- DROP USER nome_do_usuario;
--
-- Descrição: Remove o usuário especificado do banco de dados.
--
DROP USER user_dummy;
```
