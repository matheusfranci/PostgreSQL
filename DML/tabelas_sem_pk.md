# Tabelas Sem Chaves Primárias ou Estrangeiras no PostgreSQL

## Descrição

Este script SQL recupera o esquema e o nome de todas as tabelas de usuário no PostgreSQL que não possuem chaves primárias ou estrangeiras definidas. Ele exclui tabelas dos esquemas do sistema (`pg_catalog` e `information_schema`).

## Query

```sql
SELECT tbl.table_schema, tbl.table_name
FROM information_schema.tables tbl
WHERE table_type = 'BASE TABLE'
AND table_schema NOT IN ('pg_catalog', 'information_schema')
AND NOT EXISTS (
    SELECT 1
    FROM information_schema.key_column_usage kcu
    WHERE kcu.table_name = tbl.table_name
        AND kcu.table_schema = tbl.table_schema
);
```

## Explicação Detalhada

* **`information_schema.tables tbl`**: Esta visão do sistema contém informações sobre tabelas no banco de dados.
* **`table_schema`**: O nome do esquema da tabela.
* **`table_name`**: O nome da tabela.
* **`WHERE table_type = 'BASE TABLE'`**: Filtra os resultados para incluir apenas tabelas base (tabelas de dados reais).
* **`AND table_schema NOT IN ('pg_catalog', 'information_schema')`**: Filtra os resultados para excluir tabelas dos esquemas do sistema.
* **`AND NOT EXISTS (...)`**: Filtra os resultados para incluir apenas tabelas que não possuem chaves primárias ou estrangeiras definidas.
    * **`information_schema.key_column_usage kcu`**: Esta visão do sistema contém informações sobre colunas de chaves (primárias e estrangeiras).
    * **`WHERE kcu.table_name = tbl.table_name AND kcu.table_schema = tbl.table_schema`**: Verifica se existe alguma coluna de chave para a tabela atual.
    * **`SELECT 1`**: Retorna um valor constante (1) se a subconsulta encontrar alguma coluna de chave.

## Exemplos de Uso

Este script pode ser usado para:

* Identificar tabelas que podem precisar de chaves primárias ou estrangeiras para garantir a integridade dos dados.
* Verificar a integridade do esquema do banco de dados.
* Auxiliar na otimização do esquema do banco de dados.

## Considerações

* A ausência de chaves primárias pode dificultar a identificação e atualização de registros únicos.
* A ausência de chaves estrangeiras pode levar a inconsistências de dados entre tabelas relacionadas.
* É importante revisar as tabelas listadas por este script e determinar se a adição de chaves é necessária.
* O script considera apenas chaves primárias e estrangeiras. Outros tipos de restrições (como `UNIQUE` ou `CHECK`) não são considerados.
* A query lista as tabelas que não possuem nenhuma chave primária ou estrangeira.
