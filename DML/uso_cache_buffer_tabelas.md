# Análise do Uso do Cache de Buffer para Tabelas no PostgreSQL

## Descrição

Esta query analisa o uso do cache de buffer para tabelas no PostgreSQL. Ela exibe o nome da tabela, o tamanho dos dados armazenados em buffer, a porcentagem do cache de buffer ocupada pela tabela e a porcentagem da tabela que está em cache.

## Query

```sql
SELECT c.relname
  , pg_size_pretty(count(*) * 8192) as buffered
  , round(100.0 * count(*) / ( SELECT setting FROM pg_settings WHERE name='shared_buffers')::integer,1) AS buffers_percent
  , round(100.0 * count(*) * 8192 / pg_relation_size(c.oid),1) AS percent_of_relation
 FROM pg_class c
 INNER JOIN pg_buffercache b ON b.relfilenode = c.relfilenode
 INNER JOIN pg_database d ON (b.reldatabase = d.oid AND d.datname = current_database())
 WHERE pg_relation_size(c.oid) > 0
 GROUP BY c.oid, c.relname
 ORDER BY 3 DESC
 LIMIT 30;
```

## Explicação Detalhada

* `pg_class c`: Tabela do sistema que contém informações sobre relações (tabelas e índices).
* `pg_buffercache b`: Visão do sistema que fornece informações sobre o conteúdo do cache de buffer.
* `pg_database d`: Tabela do sistema que contém informações sobre bancos de dados.
* `c.relname`: Nome da tabela.
* `pg_size_pretty(count(*) * 8192) as buffered`: Tamanho dos dados da tabela armazenados em buffer (em formato legível).
    * `count(*)`: Número de blocos da tabela em cache.
    * `8192`: Tamanho do bloco em bytes.
* `round(100.0 * count(*) / ( SELECT setting FROM pg_settings WHERE name='shared_buffers')::integer,1) AS buffers_percent`: Porcentagem do cache de buffer ocupada pela tabela.
    * `( SELECT setting FROM pg_settings WHERE name='shared_buffers')::integer`: Tamanho total do cache de buffer (em blocos).
* `round(100.0 * count(*) * 8192 / pg_relation_size(c.oid),1) AS percent_of_relation`: Porcentagem da tabela que está em cache.
    * `pg_relation_size(c.oid)`: Tamanho total da tabela em bytes.
* `INNER JOIN pg_buffercache b ON b.relfilenode = c.relfilenode`: Junta as tabelas `pg_class` e `pg_buffercache` com base no identificador do arquivo de relação.
* `INNER JOIN pg_database d ON (b.reldatabase = d.oid AND d.datname = current_database())`: Junta com `pg_database` para filtrar para o banco de dados atual.
* `WHERE pg_relation_size(c.oid) > 0`: Filtra para incluir apenas tabelas com tamanho maior que zero.
* `GROUP BY c.oid, c.relname`: Agrupa os resultados pelo identificador e nome da tabela.
* `ORDER BY 3 DESC`: Ordena os resultados pela porcentagem do cache de buffer ocupada pela tabela (em ordem decrescente).
* `LIMIT 30`: Limita os resultados às 30 tabelas que ocupam a maior porcentagem do cache de buffer.

## Exemplos de Uso

Esta query pode ser usada para:

* Monitorar o uso do cache de buffer para tabelas.
* Identificar tabelas que estão consumindo uma grande parte do cache de buffer.
* Avaliar a eficiência do cache de buffer.
* Auxiliar na otimização do uso da memória do servidor.

## Considerações

* O cache de buffer é uma área de memória usada para armazenar dados acessados frequentemente, melhorando o desempenho de consultas.
* Tabelas que ocupam uma grande parte do cache de buffer podem indicar que elas são acessadas com frequência.
* A porcentagem da tabela que está em cache indica a proporção dos dados da tabela que estão armazenados em memória.
* A query filtra para o banco de dados atual.
* O número de tabelas retornadas é limitado a 30.
* Essa consulta pode ser cara em servidores com muitos dados.
