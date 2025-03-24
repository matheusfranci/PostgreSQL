# Listar Triggers em Tabelas de Usuário no PostgreSQL

## Descrição

Esta query lista informações sobre triggers definidos em tabelas de usuário no PostgreSQL. Ela exibe o esquema, o nome da tabela, o nome do trigger, a função chamada pelo trigger, a tabela de restrição (se aplicável), o modo do trigger e o ID do índice de restrição (se aplicável).

## Query

```sql
SELECT n.nspname AS schema,
       c.relname AS table,
       t.tgname AS trigger,
       p.proname AS function_called,
       CASE WHEN t.tgconstrrelid > 0
            THEN (SELECT relname
                  FROM pg_class
                  WHERE oid = t.tgconstrrelid)
            ELSE ''
       END AS constr_tbl,
       t.tgenabled AS mode,
       t.tgconstrindid
FROM pg_trigger t
INNER JOIN pg_proc p ON (p.oid = t.tgfoid)
INNER JOIN pg_class c ON (c.oid = t.tgrelid)
INNER JOIN pg_namespace n ON (n.oid = c.relnamespace)
WHERE tgname NOT LIKE 'pg_%'
  AND tgname NOT LIKE 'RI_%' -- < comment out to see triggers
ORDER BY 1, 2;
```

## Explicação Detalhada

* `pg_trigger t`: Tabela do sistema que contém informações sobre triggers.
* `pg_proc p`: Tabela do sistema que contém informações sobre funções e procedimentos.
* `pg_class c`: Tabela do sistema que contém informações sobre relações (tabelas e índices).
* `pg_namespace n`: Tabela do sistema que contém informações sobre namespaces (esquemas).
* `n.nspname AS schema`: Nome do esquema da tabela.
* `c.relname AS table`: Nome da tabela.
* `t.tgname AS trigger`: Nome do trigger.
* `p.proname AS function_called`: Nome da função chamada pelo trigger.
* `CASE WHEN t.tgconstrrelid > 0 THEN ... ELSE '' END AS constr_tbl`: Nome da tabela de restrição (se aplicável).
* `t.tgenabled AS mode`: Modo do trigger (por exemplo, `O` para habilitado, `D` para desabilitado).
* `t.tgconstrindid`: ID do índice de restrição (se aplicável).
* `INNER JOIN pg_proc p ON (p.oid = t.tgfoid)`: Junta `pg_trigger` com `pg_proc` para obter o nome da função chamada pelo trigger.
* `INNER JOIN pg_class c ON (c.oid = t.tgrelid)`: Junta `pg_trigger` com `pg_class` para obter o nome da tabela.
* `INNER JOIN pg_namespace n ON (n.oid = c.relnamespace)`: Junta `pg_class` com `pg_namespace` para obter o nome do esquema.
* `WHERE tgname NOT LIKE 'pg_%'`: Exclui triggers do sistema.
* `AND tgname NOT LIKE 'RI_%'`: Exclui triggers relacionados a restrições de integridade referencial (comente esta linha para ver esses triggers).
* `ORDER BY 1, 2`: Ordena os resultados pelo esquema e nome da tabela.

## Exemplos de Uso

Esta query pode ser usada para:

* Listar todos os triggers definidos em tabelas de usuário.
* Identificar quais funções são chamadas por triggers.
* Verificar o modo de triggers (habilitado ou desabilitado).
* Identificar triggers relacionados a restrições de integridade referencial (se a linha de filtro for comentada).
* Auxiliar na análise e depuração de triggers.

## Considerações

* Triggers são funções que são executadas automaticamente em resposta a eventos em tabelas (por exemplo, inserções, atualizações, exclusões).
* A coluna `constr_tbl` indica a tabela de restrição, que é usada para triggers de restrição.
* A coluna `mode` indica o modo do trigger (habilitado ou desabilitado).
* A coluna `tgconstrindid` indica o ID do índice de restrição, que é usado para triggers de restrição.
* A linha de filtro `AND tgname NOT LIKE 'RI_%'` exclui triggers relacionados a restrições de integridade referencial. Se você quiser ver esses triggers, comente essa linha.
* A ordenação facilita a análise dos triggers por esquema e tabela.
* Triggers do sistema (que começam com `pg_`) são excluídos da lista.
