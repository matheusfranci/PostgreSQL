-- Criar schema
Create schema schemaname

-- Deletar schema
Drop schema schemaname

-- setar o schema padrão que o postgre irá buscar quando o schema não for especificado na query
SET search_path TO SCHEMA1, SCHEMA2;

-- Mudar tabela de schema
 ALTER TABLE SCHEMA.SUA_TABELA SET SCHEMA NOME_SCHEMA_DESTINO;  
