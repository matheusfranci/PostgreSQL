-- Modos de parar o postgresql pelo psql
 Modos pelo psql:
 Smart
 Fast 
 Immediate
 
 Modos pelo S.O
 Kill
 
 -- Parada padrão smart
 pg_ctl -D /dir/cluster stop
 
 -- Forçando o modo de parada
 pg_ctl -m [modo] -D /dir/cluster stop
           [Smart]
           [Fast]
           [Immediate]
 
 -- Reiniciar
 pg_ctl -m [modo] -D /dir/cluster restart
           [Smart]
           [Fast]
           [Immediate]
    
-- Recarregar configuração
pg_ctl -D /dir/cluster reload

-- O que é a parada smart
-- Modo mais seguro de parar o cluster
* Espera os backups finalizar
* Espera as transações finalizarem
* Espera o encerramento de todas as sessões

-- O que é a parada fast
-- Serão encerrados pelo postgresql
* Backups em andamento
* Transações irão sofrer roolback
* Sessões

-- O que é a parada immediate
* Ele faz tudo que o fast faz de maneira não segura.
* É como se desligasse o servidor e no retorno irá demorar pois haverá uma recuperação
* Há risco de corrupção nos dados

-- Usando o systemctl para iniciar, parar e checar o status usa-se o comando abaixo
systemctl stop postgres
systemctl start postgres
systemctl STATUS postgres

-- Utilizando o pg_ctl
-- Para descobrir o diretório onde fica o arquivo pg_ctl basta utilizar o 
ps -ef | grep postgres
-- Ele geralmente fica no primeiro diretório onde tem uma basta bin

-- Comandos
-- É bom apontar o diretório do pg_ctl até para caso de múltiplos clusters no servidor
/usr/lib/postgresql/14/bin/pg_ctl -D /var/lib/postgresql/14/main stop

-- Precisa apontar para o diretório do arquivo postgresql.conf, caso contrário terá erro de que o postgresql não consegue acessas o "configuration file"
locate postgresql.conf
/usr/lib/postgresql/14/bin/pg_ctl -D /etc/postgresql/14/main/ start

-- Verificando o status e o PID para caso de necessidade de KILL
/usr/lib/postgresql/14/bin/pg_ctl -D /etc/postgresql/14/main/ status

-- Parada fast
/usr/lib/postgresql/14/bin/pg_ctl stop -D /var/lib/postgresql/14/main -m fast

-- Parada immediate
/usr/lib/postgresql/14/bin/pg_ctl stop -D /var/lib/postgresql/14/main -m immediate

-- Parada smart é similar mas em via de regra é a default
/usr/lib/postgresql/14/bin/pg_ctl stop -D /var/lib/postgresql/14/main -m smart

-- Stop pg15
/usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/15/main/ stop
