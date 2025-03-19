--
-- Script: Gerenciamento de Schemas no PostgreSQL
-- Descrição: Este script fornece exemplos de como criar, deletar, definir o search_path e mover tabelas entre schemas no PostgreSQL.
--

--
-- Criar Schema
--
-- Comando:
-- CREATE SCHEMA nome_do_schema;
--
-- Descrição: Cria um novo schema no banco de dados.
--
CREATE SCHEMA schemaname;

--
-- Deletar Schema
--
-- Comando:
-- DROP SCHEMA nome_do_schema;
--
-- Descrição: Deleta um schema existente no banco de dados.
--
DROP SCHEMA schemaname;

--
-- Definir o Schema Padrão (search_path)
--
-- Comando:
-- SET search_path TO schema1, schema2;
--
-- Descrição: Define a ordem de busca dos schemas. Quando um objeto (tabela, função, etc.) é referenciado sem especificar o schema, o PostgreSQL irá procurá-lo nos schemas listados no search_path, na ordem especificada.
--
-- Exemplo:
-- SET search_path TO public, my_schema;
--
SET search_path TO SCHEMA1, SCHEMA2;

--
-- Mover Tabela para Outro Schema
--
-- Comando:
-- ALTER TABLE schema_origem.nome_da_tabela SET SCHEMA nome_schema_destino;
--
-- Descrição: Move uma tabela de um schema para outro.
--
-- Exemplo:
-- ALTER TABLE old_schema.my_table SET SCHEMA new_schema;
--
ALTER TABLE SCHEMA.SUA_TABELA SET SCHEMA NOME_SCHEMA_DESTINO;
