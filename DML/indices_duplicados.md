# Identificar Índices Duplicados no PostgreSQL

## Descrição

Esta query identifica índices duplicados em um banco de dados PostgreSQL, agrupando-os por suas definições e calculando o tamanho total dos índices duplicados. Ela também exibe os nomes de até quatro índices duplicados para cada grupo.

## Query

```sql
SELECT pg_size_pretty(sum(pg_relation_size(idx))::bigint) as size,
       (array_agg(idx))[1] as idx1, (array_agg(idx))[2] as idx2,
       (array_agg(idx))[3] as idx3, (array_agg(idx))[4] as idx4
FROM (
    SELECT indexrelid::regclass as idx, (indrelid::text ||E'\n'|| indclass::text ||E'\n'|| indkey::text ||E'\n'||
                                         coalesce(indexprs::text,'')||E'\n' || coalesce(indpred::text,'')) as key
    FROM pg_index
) sub
GROUP BY key HAVING count(*)>1
ORDER BY sum(pg_relation_size(idx)) DESC;
```

## Explicação Detalhada

A query é dividida em duas partes principais:

1.  **Subquery:**
    * `SELECT indexrelid::regclass as idx, ...`: Seleciona o nome do índice (`indexrelid::regclass`) e o armazena na coluna `idx`.
    * `indrelid::text ||E'\n'|| indclass::text ||E'\n'|| indkey::text ||E'\n'|| coalesce(indexprs::text,'')||E'\n' || coalesce(indpred::text,'') as key`: Constrói uma chave única (`key`) concatenando informações sobre o índice, como a tabela indexada (`indrelid`), a classe de operador (`indclass`), as colunas indexadas (`indkey`), a expressão do índice (`indexprs`) e o predicado do índice (`indpred`). O `E'\n'` adiciona quebras de linha para facilitar a leitura da chave.
    * `FROM pg_index`: Obtém informações da tabela do sistema `pg_index`, que contém metadados sobre índices.

2.  **Consulta Principal:**
    * `pg_size_pretty(sum(pg_relation_size(idx))::bigint) as size`: Calcula o tamanho total dos índices duplicados em cada grupo e o exibe em um formato legível para humanos.
    * `(array_agg(idx))[1] as idx1, (array_agg(idx))[2] as idx2, ...`: Agrupa os índices duplicados por sua chave (`key`) e exibe os nomes de até quatro índices duplicados para cada grupo.
    * `GROUP BY key HAVING count(*)>1`: Agrupa os índices pela chave e filtra para incluir apenas grupos com mais de um índice (ou seja, índices duplicados).
    * `ORDER BY sum(pg_relation_size(idx)) DESC`: Ordena os resultados pelo tamanho total dos índices duplicados em ordem decrescente.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar índices duplicados que ocupam espaço desnecessário.
* Otimizar o uso do espaço em disco.
* Melhorar o desempenho do banco de dados removendo índices redundantes.
* Auxiliar na análise e limpeza de índices.

## Considerações

* Índices duplicados podem ocorrer devido a erros de criação de índice ou migrações de esquema.
* Remover índices duplicados pode liberar espaço em disco e melhorar o desempenho de operações de escrita.
* Antes de remover um índice duplicado, certifique-se de que ele não seja usado por nenhuma consulta importante.
* A coluna `key` representa a definição do índice, e índices com a mesma `key` são considerados duplicados.
* A query exibe apenas os nomes de até quatro índices duplicados para cada grupo. Se houver mais de quatro índices duplicados, os nomes adicionais não serão exibidos.
