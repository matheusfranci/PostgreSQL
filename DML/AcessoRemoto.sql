-- Habilitar o acesso remoto
vim /var/lib/psql/13/data/postgresql.conf
listen_address='*'

-- Depois configurar:
sudo vim /var/lib/pgsql/12/data/pg_hba.conf
# Accept from anywhere
host all all 0.0.0./0 md5

# Accept from trusted subnet
host all all 192.168.0.0/24 md5

Depois basta reiniciar os serviços
sudo systemctl restart postgresql-13
psql -U postgres
postgres=> select pg_reload_conf();
