## Análise do Progresso de Criação de Índices no PostgreSQL

As queries apresentadas visam monitorar o progresso da criação de índices no PostgreSQL. Elas consultam visões do sistema que fornecem informações em tempo real sobre as operações de criação de índice em andamento.

### Primeira Query: Informações Básicas do Progresso

```sql
SELECT
    phase,
    blocks_total,
    blocks_done,
    tuples_total,
    tuples_done,
    index_relid::regclass
FROM
    pg_stat_progress_create_index;
```

**Descrição:**

Esta query seleciona informações básicas sobre o progresso de cada operação de criação de índice ativa no momento. As colunas retornadas são:

* `phase`: Indica a fase atual do processo de criação do índice (e.g., 'initializing', 'scanning heap', 'sorting', 'writing index').
* `blocks_total`: O número total de blocos de disco que precisam ser processados para esta fase.
* `blocks_done`: O número de blocos de disco que já foram processados nesta fase.
* `tuples_total`: O número total de tuplas (linhas) que precisam ser processadas (pode ser estimado ou desconhecido em algumas fases).
* `tuples_done`: O número de tuplas que já foram processadas.
* `index_relid::regclass`: O OID (Object Identifier) do índice em construção, convertido para o nome legível do índice.

Essa query fornece um panorama geral das criações de índice em andamento e o progresso em termos de blocos e tuplas processadas.

### Segunda Query: Detalhes do Progresso com Informações Adicionais

```sql
SELECT
    now()::time(0),
    a.query,
    p.phase,
    p.blocks_total,
    p.blocks_done,
    p.tuples_total,
    p.tuples_done,
    ai.schemaname,
    ai.relname,
    ai.indexrelname
FROM
    pg_stat_progress_create_index p
    JOIN pg_stat_activity a ON p.pid = a.pid
    LEFT JOIN pg_stat_all_indexes ai ON ai.relid = p.relid AND ai.indexrelid = p.index_relid;
```

**Descrição:**

Esta query é mais detalhada e combina informações sobre o progresso da criação do índice com detalhes sobre a atividade do processo e os nomes do esquema, tabela e índice. As colunas retornadas incluem:

* `now()::time(0)`: A hora atual (sem os microssegundos) em que a consulta foi executada.
* `a.query`: A consulta SQL que iniciou a criação do índice.
* `p.phase`: A fase atual do processo de criação do índice (igual à primeira query).
* `p.blocks_total`: O número total de blocos a serem processados (igual à primeira query).
* `p.blocks_done`: O número de blocos já processados (igual à primeira query).
* `p.tuples_total`: O número total de tuplas a serem processadas (igual à primeira query).
* `p.tuples_done`: O número de tuplas já processadas (igual à primeira query).
* `ai.schemaname`: O nome do esquema da tabela na qual o índice está sendo criado.
* `ai.relname`: O nome da tabela na qual o índice está sendo criado.
* `ai.indexrelname`: O nome do índice que está sendo criado.

**Junções:**

* `JOIN pg_stat_activity a ON p.pid = a.pid`: Realiza uma junção com a visão `pg_stat_activity` para obter informações sobre a atividade do processo (PID) que está executando a criação do índice, incluindo a consulta original.
* `LEFT JOIN pg_stat_all_indexes ai ON ai.relid = p.relid AND ai.indexrelid = p.index_relid`: Realiza uma junção esquerda com a visão `pg_stat_all_indexes` para obter os nomes do esquema, tabela e índice. A junção é feita com base nos OIDs da relação e do índice. A `LEFT JOIN` garante que as informações de progresso sejam exibidas mesmo que o índice ainda não esteja totalmente registrado em `pg_stat_all_indexes`.

**Utilidade:**

Esta segunda query é mais útil para monitorar em tempo real o progresso de uma criação de índice específica, pois fornece o horário da consulta, a instrução SQL original e os nomes completos do esquema, tabela e índice envolvidos. Isso facilita a identificação e o acompanhamento de operações de criação de índice de longa duração.
