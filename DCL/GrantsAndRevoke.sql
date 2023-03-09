-- Principais Roles
pg_checkpoint	 	 	 	 	 	 	 	 
pg_database_owner	 	 	 	 	 	 	 	 
pg_execute_server_program	 	 	 	 	 	 	 	 
pg_maintain	 	 	 	 	 	 	 	 
pg_monitor	 	 	 	 	 	 	 	 
pg_read_all_data	 	 	 	 	 	 	 	 
pg_read_all_settings	 	 	 	 	 	 	 	 
pg_read_all_stats	 	 	 	 	 	 	 	 
pg_read_server_files	 	 	 	 	 	 	 	 
pg_signal_backend	 	 	 	 	 	 	 	 
pg_stat_scan_tables	 	 	 	 	 	 	 	 
pg_use_reserved_connections	 	 	 	 	 	 	 	 
pg_write_all_data	 	 	 	 	 	 	 	 
pg_write_server_files

-- Para conceder e revogar acesso de alguma role basta seguir a lógica abaixo
GRANT NOMEDAROLE TO USUÁRIO;
REVOKE NOMEDAROLE TO USUÁRIO;

-- Para conceder e revogar acesso a um objeto basta seguir a lógica abaixo
GRANT SELECT ON OBJECT_NAME TO USUÁRIO;
GRANT INSERT ON OBJECT_NAME TO USUÁRIO;
GRANT UPDATE ON OBJECT_NAME TO USUÁRIO;
GRANT DELETE ON OBJECT_NAME TO USUÁRIO;
GRANT TRUNCATE ON OBJECT_NAME TO USUÁRIO;
GRANT REFERENCES ON OBJECT_NAME TO USUÁRIO;
GRANT TRIGGER ON OBJECT_NAME TO USUÁRIO;
GRANT CREATE ON OBJECT_NAME TO USUÁRIO;
GRANT CONNECT ON OBJECT_NAME TO USUÁRIO;
GRANT TEMPORARY ON OBJECT_NAME TO USUÁRIO;
GRANT EXECUTE ON OBJECT_NAME TO USUÁRIO;
GRANT USAGE ON OBJECT_NAME TO USUÁRIO;
GRANT SET ON OBJECT_NAME TO USUÁRIO;
GRANT ALTER SYSTEM ON OBJECT_NAME TO USUÁRIO;

REVOKE SELECT ON OBJECT_NAME TO USUÁRIO;
REVOKE INSERT ON OBJECT_NAME TO USUÁRIO;
REVOKE UPDATE ON OBJECT_NAME TO USUÁRIO;
REVOKE DELETE ON OBJECT_NAME TO USUÁRIO;
REVOKE TRUNCATE ON OBJECT_NAME TO USUÁRIO;
REVOKE REFERENCES ON OBJECT_NAME TO USUÁRIO;
REVOKE TRIGGER ON OBJECT_NAME TO USUÁRIO;
REVOKE CREATE ON OBJECT_NAME TO USUÁRIO;
REVOKE CONNECT ON OBJECT_NAME TO USUÁRIO;
REVOKE TEMPORARY ON OBJECT_NAME TO USUÁRIO;
REVOKE EXECUTE ON OBJECT_NAME TO USUÁRIO;
REVOKE USAGE ON OBJECT_NAME TO USUÁRIO;
REVOKE SET ON OBJECT_NAME TO USUÁRIO;
REVOKE ALTER SYSTEM ON OBJECT_NAME TO USUÁRIO;

-- Ao adicionar a cláusula "WITH GRANT OPTION" ao final do comando, o usuário no qual o provilégio foi concedido poderá conceder o mesmo privilégio a outros usuários
-- segue exemplo:
GRANT ALTER SYSTEM ON OBJECT_NAME TO USUÁRIO WITH GRANT OPTION;
