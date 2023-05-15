/*Para remover objetos de banco de dados antes de recriá-los, use a opção –c.
Para construir um banco de dados antes de restaurá-lo, use a opção -C.*/

-- No pg_dump as roles(usuários) não são exportados então o método correto é utilizar o pg_dumpall
pg_dumpall --roles-only > c:\pgdump\allroles.sql

--To dump all databases:

$ pg_dumpall -p 5432 -U postgres -h hostname > cluster.sql
--To restore database(s) from this file, you can use:

-- Restore com recriação dos objetos
$ psql -p 5432 -U postgres -h hostname -c < /caminho/do/arquivo.sql
