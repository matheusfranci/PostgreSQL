# Listar as 5 Maiores Tabelas no PostgreSQL

## Descrição

Esta query lista as 5 maiores tabelas em um banco de dados PostgreSQL, excluindo índices e tabelas do sistema. Ela exibe o nome da tabela e seu tamanho total em um formato legível para humanos.

## Query

```sql
SELECT
    relname AS "relation",
    pg_size_pretty(
        pg_total_relation_size(C.oid)
    ) AS "total_size"
FROM
    pg_class C
LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
WHERE
    nspname NOT IN (
        'pg_catalog',
        'information_schema'
    )
AND C.relkind <> 'i'
AND nspname !~ '^pg_toast'
ORDER BY
    pg_total_relation_size(C.oid) DESC
LIMIT 5;
```

## Explicação Detalhada

* `pg_class C`: Tabela do sistema que contém informações sobre relações (tabelas e índices).
* `pg_namespace N`: Tabela do sistema que contém informações sobre namespaces (esquemas).
* `relname AS "relation"`: Nome da tabela.
* `pg_size_pretty(pg_total_relation_size(C.oid)) AS "total_size"`: Tamanho total da tabela em formato legível para humanos (por exemplo, "GB", "MB", "KB").
* `pg_total_relation_size(C.oid)`: Função que retorna o tamanho total da tabela em bytes, incluindo o tamanho da tabela principal e seus índices.
* `nspname NOT IN ('pg_catalog', 'information_schema')`: Exclui tabelas dos esquemas do sistema.
* `C.relkind <> 'i'`: Exclui índices.
* `nspname !~ '^pg_toast'`: Exclui tabelas TOAST (armazenamento de valores grandes).
* `ORDER BY pg_total_relation_size(C.oid) DESC`: Ordena os resultados pelo tamanho total da tabela em ordem decrescente.
* `LIMIT 5`: Limita os resultados às 5 maiores tabelas.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar as maiores tabelas em um banco de dados.
* Monitorar o espaço em disco ocupado pelas tabelas.
* Auxiliar na análise de espaço em disco.
* Identificar tabelas que podem precisar de otimização.

## Considerações

* O tamanho total da tabela inclui o tamanho da tabela principal e seus índices.
* A query exclui tabelas do sistema e tabelas TOAST.
* O número de tabelas retornadas pode ser ajustado alterando o valor do `LIMIT`.
* A ordenação é realizada pelo tamanho total da tabela em ordem decrescente.
* Essa consulta pode demorar em bancos de dados muito grandes.
