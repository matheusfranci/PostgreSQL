# Contagem de Linhas em Tabelas com Padrão de Nome no PostgreSQL

## Descrição

Este script SQL recupera o nome e o número estimado de linhas de tabelas no PostgreSQL que correspondem a um padrão de nome especificado, excluindo tabelas dos esquemas do sistema (`pg_catalog` e `information_schema`).

## Query

```sql
SELECT relname, reltuples::numeric
FROM pg_class pg, information_schema.tables i
WHERE pg.relname = i.table_name
AND relkind = 'r'
AND table_schema NOT IN ('pg_catalog', 'information_schema')
AND pg.relname LIKE '<table-name>_%'
ORDER BY pg.relname DESC;
```

## Explicação Detalhada

* **`pg_class pg`**: Esta tabela do sistema contém informações sobre classes (tabelas, índices, etc.).
* **`information_schema.tables i`**: Esta visão do sistema contém informações sobre tabelas no banco de dados.
* **`pg.relname, reltuples::numeric`**: Seleciona o nome da tabela (`relname`) e o número estimado de linhas (`reltuples`), convertendo o último para um tipo numérico.
* **`WHERE pg.relname = i.table_name`**: Junta as tabelas `pg_class` e `information_schema.tables` com base no nome da tabela.
* **`AND relkind = 'r'`**: Filtra os resultados para incluir apenas tabelas regulares (`r`).
* **`AND table_schema NOT IN ('pg_catalog', 'information_schema')`**: Filtra os resultados para excluir tabelas dos esquemas do sistema.
* **`AND pg.relname LIKE '<table-name>_%'`**: Filtra os resultados para incluir apenas tabelas cujo nome corresponde ao padrão especificado. Substitua `<table-name>` pelo padrão desejado. O `_` serve como curinga para qualquer caractere.
* **`ORDER BY pg.relname DESC`**: Ordena os resultados pelo nome da tabela em ordem decrescente.

## Instruções de Uso

* Substitua `<table-name>` pelo prefixo desejado do nome das tabelas que você deseja analisar. Por exemplo, se você quiser analisar tabelas com nomes que começam com `dados_`, use `dados_`.

## Exemplos de Uso

1.  Para obter o nome e o número estimado de linhas de todas as tabelas que começam com `logs_`:

    ```sql
    SELECT relname, reltuples::numeric
    FROM pg_class pg, information_schema.tables i
    WHERE pg.relname = i.table_name
    AND relkind = 'r'
    AND table_schema NOT IN ('pg_catalog', 'information_schema')
    AND pg.relname LIKE 'logs_%'
    ORDER BY pg.relname DESC;
    ```

## Considerações

* `reltuples` é uma estimativa do número de linhas, não uma contagem exata. Para obter a contagem exata, use `SELECT COUNT(*) FROM table_name`.
* O operador `LIKE` permite usar curingas (`%` e `_`) para filtrar os resultados com base em padrões de nome.
* A ordenação por nome de tabela em ordem decrescente pode ser útil para analisar tabelas com nomes sequenciais.
* A informação de `reltuples` é atualizada por comandos como `VACUUM ANALYZE`.
* Esta query é muito útil para analisar tabelas que seguem um padrão de nomenclatura.
