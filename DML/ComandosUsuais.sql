-- Verificar processos postgresql
ps -ef postgres

-- Logar no postgres
sudo su - postgres
psql

-- verificar usuário logado
select current_user;

-- verificar database atual
select current_database();

-- verificar versão 
select version();

-- sair do psql
q/

-- verificar status dos serviços do postgres
systemctl status postgresql-13
