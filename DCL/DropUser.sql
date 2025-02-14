-- Remova todos os privilégios a nível de banco
revoke all on database database_dummy from user_dummy;

-- Gere os comandos para remover os privilégios dos schemas, sequences e tabelas
select 'REVOKE ALL PRIVILEGES ON SCHEMA ' || schema_name || ' FROM user_dummy;'
from information_schema.schemata
where schema_name not in ('information_schema', 'pg_catalog', 'public')
union ALL
select 'REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ' || schema_name || ' FROM user_dummy;'
from information_schema.schemata
where schema_name not in ('information_schema', 'pg_catalog', 'public')
union ALL
select 'REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA ' || schema_name || ' FROM user_dummy;'
from information_schema.schemata
where schema_name not in ('information_schema', 'pg_catalog', 'public')

-- Para finalizar, drop o usuário
drop user user_dummy;
