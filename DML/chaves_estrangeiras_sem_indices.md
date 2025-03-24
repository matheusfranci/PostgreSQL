# Identificar Chaves Estrangeiras Sem Índices Correspondentes no PostgreSQL

## Descrição

Esta query identifica chaves estrangeiras em um banco de dados PostgreSQL que não possuem índices correspondentes. A falta de índices em chaves estrangeiras pode degradar o desempenho de consultas que envolvem junções (joins) entre tabelas.

## Query

```sql
SELECT c.conrelid::regclass AS "table",
       /* list of key column names in order */
       string_agg(a.attname, ',' ORDER BY x.n) AS columns,
       pg_catalog.pg_size_pretty(
           pg_catalog.pg_relation_size(c.conrelid)
       ) AS size,
       c.conname AS constraint,
       c.confrelid::regclass AS referenced_table
FROM pg_catalog.pg_constraint c
    /* enumerated key column numbers per foreign key */
    CROSS JOIN LATERAL
        unnest(c.conkey) WITH ORDINALITY AS x(attnum, n)
    /* name for each key column */
    JOIN pg_catalog.pg_attribute a
        ON a.attnum = x.attnum
        AND a.attrelid = c.conrelid
WHERE NOT EXISTS
        /* is there a matching index for the constraint? */
        (SELECT 1 FROM pg_catalog.pg_index i
        WHERE i.indrelid = c.conrelid
            /* it must not be a partial index */
            AND i.indpred IS NULL
            /* the first index columns must be the same as the
                 key columns, but order doesn't matter */
            AND (i.indkey::smallint[])[0:cardinality(c.conkey)-1]
                OPERATOR(pg_catalog.@>) c.conkey)
    AND c.contype = 'f'
GROUP BY c.conrelid, c.conname, c.confrelid
ORDER BY pg_catalog.pg_relation_size(c.conrelid) DESC;
```

## Explicação Detalhada

A query é composta por várias partes:

1.  **Seleção de Colunas:**
    * `c.conrelid::regclass AS "table"`: Nome da tabela com a chave estrangeira.
    * `string_agg(a.attname, ',' ORDER BY x.n) AS columns`: Lista de colunas da chave estrangeira, separadas por vírgulas.
    * `pg_catalog.pg_size_pretty(pg_catalog.pg_relation_size(c.conrelid)) AS size`: Tamanho da tabela com a chave estrangeira (formato legível).
    * `c.conname AS constraint`: Nome da restrição de chave estrangeira.
    * `c.confrelid::regclass AS referenced_table`: Nome da tabela referenciada pela chave estrangeira.

2.  **`FROM pg_catalog.pg_constraint c`:**
    * Seleciona dados da tabela `pg_constraint`, que contém informações sobre restrições (constraints).

3.  **`CROSS JOIN LATERAL unnest(c.conkey) WITH ORDINALITY AS x(attnum, n)`:**
    * `unnest(c.conkey)`: Expande o array `c.conkey` (colunas da chave estrangeira) em linhas.
    * `WITH ORDINALITY`: Adiciona uma coluna `n` com a ordem das colunas.
    * `AS x(attnum, n)`: Define aliases para as colunas resultantes (`attnum` e `n`).

4.  **`JOIN pg_catalog.pg_attribute a ON a.attnum = x.attnum AND a.attrelid = c.conrelid`:**
    * Junta a tabela `pg_attribute` (informações sobre colunas) para obter os nomes das colunas da chave estrangeira.

5.  **`WHERE NOT EXISTS (...) AND c.contype = 'f'`:**
    * `c.contype = 'f'`: Filtra para incluir apenas restrições de chave estrangeira.
    * `NOT EXISTS (...)`: Verifica se existe um índice correspondente para a chave estrangeira.
        * `SELECT 1 FROM pg_catalog.pg_index i`: Seleciona dados da tabela `pg_index` (informações sobre índices).
        * `WHERE i.indrelid = c.conrelid`: Filtra para incluir índices na mesma tabela da chave estrangeira.
        * `AND i.indpred IS NULL`: Exclui índices parciais.
        * `AND (i.indkey::smallint[])[0:cardinality(c.conkey)-1] OPERATOR(pg_catalog.@>) c.conkey`: Verifica se as colunas do índice são as mesmas da chave estrangeira. O operador `@>` verifica se o array da chave estrangeira está contido no array de colunas do índice.

6.  **`GROUP BY c.conrelid, c.conname, c.confrelid`:**
    * Agrupa os resultados por tabela, nome da restrição e tabela referenciada.

7.  **`ORDER BY pg_catalog.pg_relation_size(c.conrelid) DESC`:**
    * Ordena os resultados pelo tamanho da tabela em ordem decrescente.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar chaves estrangeiras que podem estar causando lentidão em junções.
* Otimizar o desempenho de consultas adicionando índices nas colunas de chaves estrangeiras.
* Auxiliar na análise e otimização do esquema do banco de dados.
* Monitorar e manter o desempenho do banco de dados.

## Considerações

* A falta de índices em chaves estrangeiras pode levar a varreduras de tabela completas durante junções.
* Adicionar índices nas colunas de chaves estrangeiras pode melhorar significativamente o desempenho de consultas.
* Antes de adicionar índices, avalie o impacto no desempenho de escrita (inserções, atualizações, exclusões).
* Considere adicionar índices compostos se a chave estrangeira envolver várias colunas.
* A query não identifica índices que não são usados, apenas a falta de índices.
