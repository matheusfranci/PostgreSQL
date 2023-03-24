-- Criar diretório /backup
mkdir /backup

-- Setar permissão para usuário e grupo postgres:
chown postgres:postgres /backup/ -R
chmod -R 700 /backup

-- Restauração do banco com o dump
psql -d brasil < /backup/brasil.sql >> /backup/brasil.log 2>&1
                                    >> gera o log

-- Exportação de tabela de html
psql -d brasil -A -H -c "select * from weather_conditions;" > tempo.html

-A e -H é para gerar o arquivo html e -c é para incluir a query no export

-- Exportação de csv
psql -d brasil -A -F ";" -c "select * from weather_conditions;" > tempo.csv

-A e -F é para gerar o arquivo csv, -c é para incluir a query no export e ";" é o delimitador
