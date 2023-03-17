-- Lista os bancos
\l

-- Lista os bancos com mais detalhes
\l+

-- Conecta em um banco no cluster
\c database_name

-- Lista as tabelas
\d+

-- Mostra os diretórios dos dados dentro do psql
show data_directory;

-- restart de parâmetros no postgresql
SELECT pg_reload_conf();                  -- Dinâmicos
systemctl restart postgresql-13           -- Não dinâmicos
