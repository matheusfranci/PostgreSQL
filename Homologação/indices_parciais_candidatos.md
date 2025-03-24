# Índices Candidatos a Índices Parciais no PostgreSQL

## Descrição

Este script SQL identifica índices no PostgreSQL que podem se beneficiar da transformação em índices parciais, especialmente aqueles com uma alta fração de valores nulos. Ele fornece informações sobre o tamanho do índice, se é único, a coluna indexada, a fração de valores nulos e a economia esperada em tamanho se o índice fosse parcial.

## Query

```sql
SELECT
    c.oid,
    c.relname AS index,
    pg_size_pretty(pg_relation_size(c.oid)) AS index_size,
    i.indisunique AS unique,
    a.attname AS indexed_column,
    CASE s.null_frac
        WHEN 0 THEN ''
        ELSE TO_CHAR(s.null_frac * 100, '999.00%')
    END AS null_frac,
    pg_size_pretty((pg_relation_size(c.oid) * s.null_frac)::BIGINT) AS expected_saving
    -- Uncomment to include the index definition
    -- , ixs.indexdef
FROM pg_class c
JOIN pg_index i ON i.indexrelid = c.oid
JOIN pg_attribute a ON a.attrelid = c.oid
JOIN pg_class c_table ON c_table.oid = i.indrelid
JOIN pg_indexes ixs ON c.relname = ixs.indexname
LEFT JOIN pg_stats s ON s.tablename = c_table.relname AND a.attname = s.attname
WHERE NOT i.indisprimary
    AND i.indpred IS NULL
    AND ARRAY_LENGTH(i.indkey, 1) = 1
    AND pg_relation_size(c.oid) > 10 * 1024 ^ 2
ORDER BY pg_relation_size(c.oid) * s.null_frac DESC;
```

## Explicação Detalhada

* **`pg_class c`**: Contém informações sobre relações (tabelas, índices, etc.).
* **`pg_index i`**: Contém informações sobre índices.
* **`pg_attribute a`**: Contém informações sobre atributos (colunas).
* **`pg_class c_table`**: Contém informações sobre a tabela associada ao índice.
* **`pg_indexes ixs`**: Contém informações sobre índices, incluindo a definição do índice.
* **`pg_stats s`**: Contém estatísticas sobre colunas de tabelas.
* **`c.oid`**: O identificador do objeto do índice.
* **`c.relname AS index`**: O nome do índice.
* **`pg_size_pretty(pg_relation_size(c.oid)) AS index_size`**: O tamanho do índice em um formato legível.
* **`i.indisunique AS unique`**: Indica se o índice é único.
* **`a.attname AS indexed_column`**: O nome da coluna indexada.
* **`CASE s.null_frac ... END AS null_frac`**: A fração de valores nulos na coluna indexada, formatada como porcentagem.
* **`pg_size_pretty((pg_relation_size(c.oid) * s.null_frac)::BIGINT) AS expected_saving`**: A economia esperada em tamanho se o índice fosse parcial, calculada com base na fração de nulos.
* **`WHERE NOT i.indisprimary`**: Exclui índices de chave primária (que não podem ser parciais).
* **`AND i.indpred IS NULL`**: Exclui índices que já são parciais.
* **`AND ARRAY_LENGTH(i.indkey, 1) = 1`**: Exclui índices compostos (que indexam várias colunas).
* **`AND pg_relation_size(c.oid) > 10 * 1024 ^ 2`**: Exclui índices menores que 10 MB.
* **`ORDER BY pg_relation_size(c.oid) * s.null_frac DESC`**: Ordena os resultados pela economia esperada em tamanho em ordem decrescente.

## Exemplos de Uso

Este script pode ser usado para:

* Identificar índices que podem se beneficiar da transformação em índices parciais.
* Reduzir o tamanho dos índices e melhorar o desempenho das consultas.
* Otimizar o uso do espaço em disco.

## Considerações

* Índices parciais indexam apenas um subconjunto das linhas de uma tabela, com base em uma condição especificada.
* Índices parciais são especialmente úteis para colunas com uma alta fração de valores nulos ou para tabelas com uma grande quantidade de dados que são raramente acessados.
* A transformação de um índice em parcial pode reduzir significativamente o tamanho do índice e melhorar o desempenho das consultas que usam o índice.
* A decisão de transformar um índice em parcial deve ser baseada em uma análise cuidadosa dos padrões de consulta e da distribuição dos dados.
* Para criar um índice parcial, é necessário adicionar a cláusula `WHERE` na declaração `CREATE INDEX`.
