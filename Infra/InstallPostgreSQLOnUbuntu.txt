-- Atualizando o SO
sudo apt-get update && sudo apt-get upgrade

-- Instalando o postgresql
sudo apt install postgresql postgresql-contrib

-- Iniciando o serviço
sudo systemctl start postgresql.service

-- Acessando o usuário postgresql
sudo -i -u postgres

-- Acessando o promtp do database, equivalente ao sqlplus do oracle
psql

-- Esse comando ira trazer voce ao prompt do linux novamente
\q

exit

-- Esse comando irá logar você no psql direto
sudo -u postgres psql

-- Saia novamente
\q

-- Criará um usuário no banco, ideal que ele exista no SO
sudo -u postgres createuser --interactive

Output
Enter name of role to add: mat
Shall the new role be a superuser? (y/n) y

-- Criando um banco
createdb databasename

-- Caso não vá crie o banco como sudo
sudo -u postgres createdb databasename

-- Adicione o usuário como um sudoer
sudo adduser sammy

-- Formas de logar no psql
sudo -i -u sammy
psql

sudo -u sammy psql

psql -d database_name


-- Verificando onde está logado após acessar a instância
\conninfo

-- Verificando status do serviço do banco
sudo systemctl status postgresql.service
