# Bloqueios em Tabelas e Cancelamento de Processos no PostgreSQL

## Descrição

Este arquivo contém duas queries PostgreSQL relacionadas a bloqueios em tabelas e cancelamento de processos.

## Query 1: Bloqueios em Tabelas

Esta query lista informações sobre bloqueios em tabelas de usuário no PostgreSQL, excluindo tabelas do sistema.

```sql
SELECT t.schemaname,
       t.relname,
       l.locktype,
       l.page,
       l.virtualtransaction,
       l.pid,
       l.mode,
       l.granted
FROM pg_locks l
JOIN pg_stat_all_tables t ON l.relation = t.relid
WHERE t.schemaname <> 'pg_toast'::name AND t.schemaname <> 'pg_catalog'::name
ORDER BY t.schemaname, t.relname;
```

## Explicação Detalhada

* `pg_locks l`: Visão do sistema que contém informações sobre bloqueios.
* `pg_stat_all_tables t`: Visão do sistema que contém estatísticas sobre todas as tabelas.
* `t.schemaname`: Nome do esquema da tabela.
* `t.relname`: Nome da tabela.
* `l.locktype`: Tipo de bloqueio (por exemplo, `relation`, `transactionid`).
* `l.page`: Página bloqueada (se aplicável).
* `l.virtualtransaction`: ID da transação virtual (se aplicável).
* `l.pid`: ID do processo (PID) que está segurando o bloqueio.
* `l.mode`: Modo do bloqueio (por exemplo, `ACCESS SHARE`, `ACCESS EXCLUSIVE`).
* `l.granted`: Indica se o bloqueio foi concedido.
* `JOIN pg_stat_all_tables t ON l.relation = t.relid`: Junta as tabelas `pg_locks` e `pg_stat_all_tables` com base no ID da relação.
* `WHERE t.schemaname <> 'pg_toast'::name AND t.schemaname <> 'pg_catalog'::name`: Filtra para excluir tabelas dos esquemas do sistema.
* `ORDER BY t.schemaname, t.relname`: Ordena os resultados por esquema e nome da tabela.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar bloqueios que estão impedindo outras queries de serem executadas.
* Diagnosticar problemas de desempenho causados por bloqueios.
* Monitorar bloqueios em tabelas críticas.
* Auxiliar na resolução de deadlocks.

## Considerações

* A presença de bloqueios pode indicar problemas de concorrência no banco de dados.
* É importante analisar o modo do bloqueio (`l.mode`) para entender o tipo de bloqueio que está sendo mantido.
* O PID (`l.pid`) pode ser usado para identificar o processo que está segurando o bloqueio.
* Esta consulta lista todos os bloqueios, inclusive os concedidos.

## Query 2: Cancelar Processo

Esta query cancela um processo no PostgreSQL com base no seu PID.

```sql
SELECT pg_cancel_backend('%pid%');
```

## Explicação Detalhada

* `pg_cancel_backend('%pid%')`: Função que cancela um processo com o PID fornecido.
* `%pid%`: Substitua `%pid%` pelo PID do processo que você deseja cancelar.

## Exemplos de Uso

Esta query pode ser usada para:

* Cancelar processos que estão segurando bloqueios por muito tempo.
* Cancelar processos que estão consumindo muitos recursos.
* Cancelar processos que estão executando queries lentas.

## Considerações

* Cancelar um processo pode interromper transações em andamento e causar perda de dados.
* Use esta query com cautela e apenas quando necessário.
* Certifique-se de que você tem permissões suficientes para cancelar processos.
* Antes de cancelar um processo, tente identificar a causa do problema e resolver o problema de forma mais adequada.
* O PID do processo pode ser obtido usando a primeira query ou outras ferramentas de monitoramento do sistema.
* O comando retorna verdadeiro se o processo foi cancelado com sucesso.
