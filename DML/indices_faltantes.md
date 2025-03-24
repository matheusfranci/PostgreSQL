# Tabelas Sem Chaves Primárias, Tabelas Sem Índices Únicos e Tabelas com Colunas de Geometria Sem Índices

## Descrição

Este arquivo contém três queries PostgreSQL para identificar tabelas sem chaves primárias, tabelas sem índices únicos e tabelas com colunas de geometria sem índices.

## Query 1: Tabelas Sem Chaves Primárias

Esta query lista todas as tabelas de usuário (excluindo tabelas do sistema) que não possuem chaves primárias.

```sql
SELECT c.table_schema, c.table_name, c.table_type
FROM information_schema.tables c
WHERE c.table_type = 'BASE TABLE' AND c.table_schema NOT IN('information_schema', 'pg_catalog')
AND NOT EXISTS (SELECT cu.table_name
                FROM information_schema.key_column_usage cu
                WHERE cu.table_schema = c.table_schema AND
                    cu.table_name = c.table_name)
ORDER BY c.table_schema, c.table_name;
```

## Explicação Detalhada

* `information_schema.tables c`: Obtém informações sobre tabelas.
* `c.table_type = 'BASE TABLE'`: Filtra para incluir apenas tabelas de base (tabelas de usuário).
* `c.table_schema NOT IN('information_schema', 'pg_catalog')`: Exclui tabelas dos esquemas do sistema.
* `NOT EXISTS (SELECT ...)`: Verifica se não existem entradas na tabela `information_schema.key_column_usage` para a tabela atual.
* `information_schema.key_column_usage cu`: Obtém informações sobre colunas de chave.
* `cu.table_schema = c.table_schema AND cu.table_name = c.table_name`: Verifica se a tabela tem colunas de chave.
* `ORDER BY c.table_schema, c.table_name`: Ordena os resultados por esquema e nome da tabela.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar tabelas que podem precisar de chaves primárias para otimizar o desempenho e garantir a integridade dos dados.
* Auxiliar na análise e otimização do esquema do banco de dados.

## Query 2: Tabelas Sem Índices Únicos e Sem Chaves Primárias

Esta query lista todas as tabelas de usuário (excluindo tabelas do sistema) que não possuem índices únicos e não possuem chaves primárias.

```sql
SELECT c.table_schema, c.table_name, c.table_type
FROM information_schema.tables c
WHERE c.table_schema NOT IN('information_schema', 'pg_catalog') AND c.table_type = 'BASE TABLE'
AND NOT EXISTS(SELECT i.tablename
                FROM pg_catalog.pg_indexes i
            WHERE i.schemaname = c.table_schema
                AND i.tablename = c.table_name AND indexdef LIKE '%UNIQUE%')
AND NOT EXISTS (SELECT cu.table_name
                FROM information_schema.key_column_usage cu
                WHERE cu.table_schema = c.table_schema AND
                    cu.table_name = c.table_name)
ORDER BY c.table_schema, c.table_name;
```

## Explicação Detalhada

* Similar à Query 1, mas adiciona a condição `NOT EXISTS(SELECT ...)` para verificar a ausência de índices únicos.
* `pg_catalog.pg_indexes i`: Obtém informações sobre índices.
* `i.schemaname = c.table_schema AND i.tablename = c.table_name AND indexdef LIKE '%UNIQUE%'`: Verifica se existem índices únicos para a tabela.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar tabelas que podem precisar de índices únicos para otimizar o desempenho e garantir a unicidade dos dados.
* Auxiliar na análise e otimização do esquema do banco de dados.

## Query 3: Tabelas com Colunas de Geometria Sem Índices

Esta query lista todas as tabelas que possuem colunas do tipo `geometry` e não possuem índices nessas colunas.

```sql
SELECT c.table_schema, c.table_name, c.column_name
FROM (SELECT * FROM
    information_schema.tables WHERE table_type = 'BASE TABLE') As t INNER JOIN
    (SELECT * FROM information_schema.columns WHERE udt_name = 'geometry') c
        ON (t.table_name = c.table_name AND t.table_schema = c.table_schema)
        LEFT JOIN pg_catalog.pg_indexes i ON
            (i.tablename = c.table_name AND i.schemaname = c.table_schema
                AND indexdef LIKE '%' || c.column_name || '%')
WHERE i.tablename IS NULL
ORDER BY c.table_schema, c.table_name;
```

## Explicação Detalhada

* `information_schema.tables t`: Obtém informações sobre tabelas de base.
* `information_schema.columns c`: Obtém informações sobre colunas.
* `c.udt_name = 'geometry'`: Filtra para incluir apenas colunas do tipo `geometry`.
* `LEFT JOIN pg_catalog.pg_indexes i ON ...`: Junta com `pg_catalog.pg_indexes` para verificar a existência de índices.
* `indexdef LIKE '%' || c.column_name || '%'`: Verifica se o índice inclui a coluna de geometria.
* `WHERE i.tablename IS NULL`: Filtra para incluir apenas tabelas sem índices nas colunas de geometria.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar tabelas com colunas de geometria que podem precisar de índices espaciais para otimizar o desempenho de consultas espaciais.
* Auxiliar na otimização de consultas espaciais.
* Identificar tabelas que necessitam de índices espaciais.

## Considerações

* As queries usam `information_schema` e `pg_catalog` para obter informações sobre tabelas e índices.
* A query 3 assume que os índices espaciais incluem o nome da coluna de geometria em sua definição.
* A ausência de índices pode degradar o desempenho de consultas que envolvem junções ou filtros nas colunas relevantes.
