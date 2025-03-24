# Cálculo de Desperdício de Espaço em Tabelas no PostgreSQL

## Descrição

Este script SQL calcula o desperdício de espaço em tabelas no PostgreSQL. Ele fornece informações sobre o tamanho total da tabela, o tamanho do TOAST, a porcentagem de desperdício de espaço e o tamanho do desperdício de espaço.

## Query

```sql
SELECT
    nspname,
    relname,
    pg_size_pretty(relation_size + toast_relation_size) AS total_size,
    pg_size_pretty(toast_relation_size) AS toast_size,
    ROUND(((relation_size - (relation_size - free_space) * 100 / fillfactor) * 100 / GREATEST(relation_size, 1))::NUMERIC, 1) AS table_waste_percent,
    pg_size_pretty((relation_size - (relation_size - free_space) * 100 / fillfactor)::BIGINT) AS table_waste,
    ROUND(((toast_free_space + relation_size - (relation_size - free_space) * 100 / fillfactor) * 100 / GREATEST(relation_size + toast_relation_size, 1))::NUMERIC, 1) AS total_waste_percent,
    pg_size_pretty((toast_free_space + relation_size - (relation_size - free_space) * 100 / fillfactor)::BIGINT) AS total_waste
FROM (
    SELECT
        nspname,
        relname,
        (SELECT free_space FROM pgstattuple(c.oid)) AS free_space,
        pg_relation_size(c.oid) AS relation_size,
        (CASE WHEN reltoastrelid = 0 THEN 0 ELSE (SELECT free_space FROM pgstattuple(c.reltoastrelid)) END) AS toast_free_space,
        COALESCE(pg_relation_size(c.reltoastrelid), 0) AS toast_relation_size,
        COALESCE((SELECT (REGEXP_MATCHES(reloptions::TEXT, E'.*fillfactor=(\\d+).*'))[1]), '100')::REAL AS fillfactor
    FROM pg_class c
    LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
    WHERE nspname NOT IN ('pg_catalog', 'information_schema')
        AND nspname !~ '^pg_toast' AND relkind = 'r'
        AND relname ~ '' -- Substitua '' pelo nome da tabela ou padrão de nome desejado
) t
ORDER BY (toast_free_space + relation_size - (relation_size - free_space) * 100 / fillfactor) DESC
LIMIT 20;
```

## Explicação Detalhada

* **Subquery Interna (`t`)**:
    * Recupera informações sobre tabelas da tabela `pg_class`.
    * Calcula o espaço livre (`free_space`) usando a função `pgstattuple`.
    * Calcula o tamanho da relação (`relation_size`) usando a função `pg_relation_size`.
    * Calcula o espaço livre do TOAST (`toast_free_space`) e o tamanho da relação TOAST (`toast_relation_size`).
    * Extrai o `fillfactor` das opções da relação usando `REGEXP_MATCHES`.
    * Filtra tabelas dos esquemas `pg_catalog`, `information_schema` e `pg_toast`.
    * `relname ~ ''` essa parte do código permite filtrar os resultados por nome de tabela, para analisar todas as tabelas, deixe em branco, para analisar apenas algumas, altere para `relname ~ 'nome_da_tabela'` ou para usar expressões regulares.
* **Query Externa**:
    * Exibe o nome do esquema (`nspname`) e o nome da relação (`relname`).
    * Calcula e exibe o tamanho total da tabela (`total_size`) e o tamanho do TOAST (`toast_size`) usando `pg_size_pretty`.
    * Calcula e exibe a porcentagem de desperdício de espaço da tabela (`table_waste_percent`) e o tamanho do desperdício de espaço da tabela (`table_waste`).
    * Calcula e exibe a porcentagem de desperdício de espaço total (`total_waste_percent`) e o tamanho do desperdício de espaço total (`total_waste`).
    * `pgstattuple` é uma função que precisa ser instalada por meio de uma extensão.
    * Ordena os resultados pelo desperdício de espaço total em ordem decrescente e limita a 20 resultados.

## Exemplos de Uso

1.  **Exibir o desperdício de espaço para todas as tabelas:**

    ```sql
    -- (Deixe a parte do 'relname ~ '' vazia)
    ```

2.  **Exibir o desperdício de espaço para uma tabela específica:**

    ```sql
    -- Substitua '' por 'nome_da_sua_tabela'
    ```

3.  **Exibir o desperdício de espaço para tabelas que correspondem a um padrão:**

    ```sql
    -- Substitua '' por um padrão de expressão regular, como 'tabela_%'
    ```

## Considerações

* O desperdício de espaço pode ocorrer devido a exclusões, atualizações e o `fillfactor` da tabela.
* O `fillfactor` determina a porcentagem de espaço que o PostgreSQL deixa livre em cada página de dados.
* Tabelas com alto desperdício de espaço podem consumir mais espaço em disco e afetar o desempenho das consultas.
* Reorganizar tabelas (`VACUUM FULL` ou `REINDEX`) pode reduzir o desperdício de espaço, mas pode ser uma operação cara.
* A extensão `pgstattuple` precisa estar instalada no banco de dados para que a query funcione corretamente.
