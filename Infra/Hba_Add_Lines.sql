-- Alterando o pg_hba de dentro do psql

-- Descobrindo o local
select setting from pg_settings where name like '%hba%';

                    setting
------------------------------------------------
 /var/lib/postgresql/data/guacamole/pg_hba.conf
(1 row)

-- Criando uma tabela
postgres=# create table hba ( lines text ); 
CREATE TABLE

-- Apontando para o arquivo
copy hba from '/var/lib/postgresql/data/guacamole/pg_hba.conf';
COPY 99

-- Select de teste
select * from hba where lines !~ '^#' and lines !~ '^$';

-- Inserindo dentro do hba
insert into hba (lines) values ('host    all             zbx_monitor             127.0.0.1/32            trust');
insert into hba (lines) values ('host    all             zbx_monitor             0.0.0.0/0 md5            md5');
insert into hba (lines) values ('host    all             zbx_monitor             ::0/0            md5');



-- Copiando para dentro do hba.conf
copy hba to '/var/lib/postgresql/data/guacamole/pg_hba.conf';


-- Verificando a mudança
select pg_read_file('pg_hba.conf');


-- Recarregando o file
select pg_reload_conf();
