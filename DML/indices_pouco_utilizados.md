# Identificar Índices Pouco Utilizados em Tabelas de Usuário no PostgreSQL

## Descrição

Esta query identifica índices não únicos que foram escaneados menos de 50 vezes e que pertencem a tabelas com mais de 5 páginas. Ela lista o nome da tabela e do índice, o tamanho do índice e o número de escaneamentos do índice.

## Query

```sql
SELECT
    schemaname || '.' || relname AS table,
    indexrelname AS index,
    pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size,
    idx_scan AS index_scans
FROM pg_stat_user_indexes ui
JOIN pg_index i ON ui.indexrelid = i.indexrelid
WHERE NOT indisunique AND idx_scan < 50 AND pg_relation_size(relid) > 5 * 8192
ORDER BY pg_relation_size(i.indexrelid) / NULLIF(idx_scan, 0) DESC NULLS FIRST,
         pg_relation_size(i.indexrelid) DESC;
```

## Explicação Detalhada

* `pg_stat_user_indexes ui`: Visão do sistema que contém estatísticas sobre índices de tabelas de usuário.
* `pg_index i`: Tabela do sistema que contém informações sobre índices.
* `schemaname || '.' || relname AS table`: Nome da tabela (esquema e nome da relação).
* `indexrelname AS index`: Nome do índice.
* `pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size`: Tamanho do índice em formato legível para humanos.
* `idx_scan AS index_scans`: Número de escaneamentos do índice.
* `NOT indisunique`: Filtra para incluir apenas índices não únicos.
* `idx_scan < 50`: Filtra para incluir apenas índices que foram escaneados menos de 50 vezes.
* `pg_relation_size(relid) > 5 * 8192`: Filtra para incluir apenas índices que pertencem a tabelas com mais de 5 páginas (8192 bytes por página).
* `ORDER BY pg_relation_size(i.indexrelid) / NULLIF(idx_scan, 0) DESC NULLS FIRST, pg_relation_size(i.indexrelid) DESC`: Ordena os resultados pelo tamanho do índice dividido pelo número de escaneamentos (em ordem decrescente) e, em seguida, pelo tamanho do índice (em ordem decrescente). O `NULLS FIRST` garante que índices com `idx_scan` igual a zero sejam listados primeiro.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar índices não únicos que são pouco utilizados e podem ser candidatos a remoção.
* Otimizar o uso do espaço em disco.
* Melhorar o desempenho de operações de escrita (inserções, atualizações, exclusões).
* Auxiliar na análise e limpeza de índices.

## Considerações

* Índices pouco utilizados podem ocupar espaço desnecessário e degradar o desempenho de operações de escrita.
* Antes de remover um índice, certifique-se de que ele não seja usado por nenhuma consulta importante.
* O limite de 50 escaneamentos (`idx_scan < 50`) e o tamanho da tabela (5 páginas) podem ser ajustados para atender às necessidades do seu ambiente.
* A ordenação prioriza índices grandes com baixo número de escaneamentos.
* A divisão por `NULLIF(idx_scan, 0)` evita erros de divisão por zero.
* A coluna `index_scans` representa o número total de index scans realizadas no índice.
