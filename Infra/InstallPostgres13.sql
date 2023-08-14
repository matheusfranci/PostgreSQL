-- Testado em oracle linux e CentOS
-- Instalando o RPM
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

-- Instalando 
yum install -y postgresql13-server

-- Iniciando o cluster
/usr/pgsql-13/bin/postgresql-13-setup initdb


-- Configuranto o serviço para iniciar junto com o servidor
systemctl enable postgresql-13
systemctl start postgresql-13

