# Listar Tipos ENUM no PostgreSQL

## Descrição

Este script SQL recupera informações sobre os tipos ENUM definidos no banco de dados PostgreSQL. Ele fornece o nome do esquema onde o ENUM está definido, o nome do ENUM e os valores que o ENUM pode assumir.

## Query

```sql
SELECT n.nspname AS enum_schema,
    t.typname AS enum_name,
    e.enumlabel AS enum_value
FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace;
```

## Explicação Detalhada

* **`pg_type t`**: Esta tabela do sistema contém informações sobre tipos de dados.
* **`pg_enum e`**: Esta tabela do sistema contém informações sobre os valores dos tipos ENUM.
* **`pg_catalog.pg_namespace n`**: Esta tabela do sistema contém informações sobre esquemas.
* **`JOIN pg_enum e ON t.oid = e.enumtypid`**: Junta as tabelas `pg_type` e `pg_enum` usando o OID do tipo ENUM (`t.oid`) e o OID do tipo ENUM na tabela `pg_enum` (`e.enumtypid`).
* **`JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace`**: Junta as tabelas resultantes com a tabela `pg_catalog.pg_namespace` usando o OID do namespace do tipo (`t.typnamespace`) e o OID do namespace (`n.oid`).
* **`n.nspname AS enum_schema`**: Seleciona o nome do esquema do ENUM e o renomeia para `enum_schema`.
* **`t.typname AS enum_name`**: Seleciona o nome do ENUM e o renomeia para `enum_name`.
* **`e.enumlabel AS enum_value`**: Seleciona o valor do ENUM e o renomeia para `enum_value`.

## Exemplos de Uso

Este script pode ser usado para:

* Obter uma lista de todos os tipos ENUM definidos no banco de dados.
* Identificar os valores que um tipo ENUM específico pode assumir.
* Verificar a existência de tipos ENUM em um esquema específico.
* Auxiliar na documentação de tipos ENUM.

## Considerações

* Tipos ENUM são úteis para representar um conjunto fixo de valores possíveis.
* A consulta retorna o esquema, nome e valores de todos os ENUMs no banco de dados.
* A ordenação dos resultados não é especificada, mas pode ser adicionada usando a cláusula `ORDER BY`.
* Caso existam muitos enums no banco de dados, o resultado da query pode ser extenso.
* Esta query é muito útil para entender a estrutura dos enums do banco de dados.
