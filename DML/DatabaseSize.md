# Listar Tamanho dos Bancos de Dados no PostgreSQL

## Descrição

Esta query lista o nome e o tamanho de todos os bancos de dados presentes no servidor PostgreSQL. O tamanho é exibido em um formato legível para humanos, como "GB" ou "MB".

## Query

```sql
SELECT pg_database.datname,
       pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database;
```

## Explicação Detalhada

* `pg_database`: Esta visão do sistema contém informações sobre todos os bancos de dados no servidor PostgreSQL.
* `pg_database.datname`: O nome do banco de dados.
* `pg_database_size(pg_database.datname)`: Função que retorna o tamanho do banco de dados em bytes.
* `pg_size_pretty(...)`: Função que converte o tamanho em bytes para um formato legível para humanos (por exemplo, "GB", "MB", "KB").
* `AS size`: Alias para a coluna que exibe o tamanho do banco de dados.

## Exemplos de Uso

Esta query pode ser usada para:

* Monitorar o espaço em disco ocupado pelos bancos de dados.
* Identificar bancos de dados grandes que podem precisar de otimização.
* Planejar a capacidade de armazenamento do servidor.
* Auxiliar na análise de espaço em disco.

## Considerações

* O tamanho exibido pela função `pg_size_pretty()` inclui todos os dados do banco de dados, incluindo tabelas, índices e arquivos de controle.
* O tamanho pode variar dependendo da quantidade de dados e da fragmentação das tabelas e índices.
* É importante monitorar o tamanho dos bancos de dados ao longo do tempo para identificar tendências de crescimento.
* Em ambientes com muitos bancos de dados, essa query pode levar algum tempo para ser executada.
