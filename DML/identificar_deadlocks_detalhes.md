# Identificar Deadlocks com Detalhes no PostgreSQL

## Descrição

Este script SQL identifica deadlocks no PostgreSQL e fornece informações detalhadas sobre os processos envolvidos, incluindo o tempo de espera, o estado da conexão, a consulta em execução e o objeto bloqueado. Ele utiliza Common Table Expressions (CTEs) recursivas para construir uma árvore de dependência de bloqueios.

## Query

```sql
WITH RECURSIVE l AS (
    SELECT pid, locktype, granted,
        ARRAY_POSITION(ARRAY['accessshare', 'rowshare', 'rowexclusive', 'shareupdateexclusive', 'share', 'sharerowexclusive', 'exclusive', 'accessexclusive'], LEFT(mode, -4)) m,
        ROW(locktype, database, relation, page, tuple, virtualxid, transactionid, classid, objid, objsubid) obj
    FROM pg_locks
),
pairs AS (
    SELECT w.pid waiter, l.pid locker, l.obj, l.m
    FROM l w JOIN l ON l.obj IS NOT DISTINCT FROM w.obj AND l.locktype = w.locktype AND NOT l.pid = w.pid AND l.granted
    WHERE NOT w.granted
        AND NOT EXISTS (SELECT FROM l i WHERE i.pid = l.pid AND i.locktype = l.locktype AND i.obj IS NOT DISTINCT FROM l.obj AND i.m > l.m)
),
leads AS (
    SELECT o.locker, 1::INT lvl, COUNT(*) q, ARRAY[locker] track, FALSE AS cycle FROM pairs o GROUP BY o.locker
    UNION ALL
    SELECT i.locker, leads.lvl + 1, (SELECT COUNT(*) FROM pairs q WHERE q.locker = i.locker), leads.track || i.locker, i.locker = ANY(leads.track)
    FROM pairs i, leads WHERE i.waiter = leads.locker AND NOT cycle
),
tree AS (
    SELECT locker pid, locker dad, locker root, CASE WHEN cycle THEN track END dl, NULL::RECORD obj, 0 lvl, locker::TEXT path, ARRAY_AGG(locker) OVER () all_pids FROM leads o
    WHERE (cycle AND NOT EXISTS (SELECT FROM leads i WHERE i.locker = ANY(o.track) AND (i.lvl > o.lvl OR i.q < o.q)))
        OR (NOT cycle AND NOT EXISTS (SELECT FROM pairs WHERE waiter = o.locker) AND NOT EXISTS (SELECT FROM leads i WHERE i.locker = o.locker AND i.lvl < o.lvl))
    UNION ALL
    SELECT w.waiter pid, tree.pid, tree.root, CASE WHEN w.waiter = ANY(tree.dl) THEN tree.dl END, w.obj, tree.lvl + 1, tree.path || '.' || w.waiter, all_pids || ARRAY_AGG(w.waiter) OVER ()
    FROM tree JOIN pairs w ON tree.pid = w.locker AND NOT w.waiter = ANY(all_pids)
)
SELECT (CLOCK_TIMESTAMP() - a.xact_start)::INTERVAL(0) AS ts_age,
    (CLOCK_TIMESTAMP() - a.state_change)::INTERVAL(0) AS change_age,
    a.datname, a.usename, a.client_addr,
    tree.pid, REPLACE(a.state, 'idle in transaction', 'idletx') state,
    lvl, (SELECT COUNT(*) FROM tree p WHERE p.path ~ ('^' || tree.path) AND NOT p.path = tree.path) blocked,
    CASE WHEN tree.pid = ANY(tree.dl) THEN '!>' ELSE REPEAT(' .', lvl) END || ' ' || TRIM(LEFT(REGEXP_REPLACE(a.query, E'\\s+', ' ', 'g'), 100)) query
FROM tree
LEFT JOIN pairs w ON w.waiter = tree.pid AND w.locker = tree.dad
JOIN pg_stat_activity a USING (pid)
JOIN pg_stat_activity r ON r.pid = tree.root
ORDER BY (NOW() - r.xact_start), path;
```

## Explicação Detalhada

A query é dividida em várias Common Table Expressions (CTEs) para organizar a lógica:

1.  **`l` CTE:**
    * Recupera informações sobre os bloqueios da tabela `pg_locks`.
    * Converte o modo de bloqueio em um número inteiro para facilitar a comparação.
    * Cria um objeto ROW para representar o objeto bloqueado.

2.  **`pairs` CTE:**
    * Identifica pares de processos que estão esperando por bloqueios um do outro.
    * Filtra os resultados para incluir apenas processos que estão esperando por bloqueios concedidos.
    * Filtra os resultados para incluir apenas processos que estão esperando pelo bloqueio mais restritivo.

3.  **`leads` CTE:**
    * Constrói uma árvore de dependência de bloqueios, identificando os processos que estão bloqueando outros processos.
    * Utiliza recursão para percorrer a árvore de dependência.
    * Identifica ciclos de bloqueio (deadlocks).

4.  **`tree` CTE:**
    * Formata a árvore de dependência de bloqueios para facilitar a visualização.
    * Inclui informações sobre o processo bloqueado, o processo bloqueador e o nível de bloqueio.
    * Identifica os processos envolvidos em deadlocks.

5.  **Consulta Principal:**
    * Seleciona as informações relevantes sobre os processos bloqueados e bloqueadores.
    * Inclui informações sobre o tempo de espera, o estado da conexão, a consulta em execução e o objeto bloqueado.
    * Formata a consulta para facilitar a leitura.
    * Ordena os resultados pelo tempo de espera e pela árvore de dependência de bloqueios.

## Exemplos de Uso

Este script pode ser usado para:

* Identificar deadlocks no banco de dados PostgreSQL.
* Analisar os processos envolvidos em deadlocks.
* Identificar as consultas que estão causando deadlocks.
* Liberar recursos do banco de dados finalizando processos bloqueados.
* Auxiliar na otimização de consultas e transações para evitar deadlocks.

## Considerações

* Deadlocks podem ocorrer quando dois ou mais processos estão esperando por bloqueios um do outro.
* A identificação e resolução de deadlocks são importantes para garantir o desempenho e a disponibilidade do banco de dados.
* Este script fornece informações detalhadas sobre os processos envolvidos em deadlocks, o que pode ajudar a identificar a causa raiz do problema.
* É importante ter cautela ao finalizar processos bloqueados, pois isso pode interromper transações importantes.
* A coluna `query` mostra a consulta em execução no momento do bloqueio, o que pode ajudar a identificar a causa do deadlock.
* A coluna `obj` mostra o objeto bloqueado, o que pode ajudar a identificar o recurso que está causando o deadlock.
* A coluna `lvl` mostra o nível de bloqueio, o que pode ajudar a identificar a profundidade da árvore de dependência de bloqueios.
* A coluna `dl` mostra os processos envolvidos em um ciclo de bloqueio (deadlock).
* Este script é uma ferramenta poderosa para diagnosticar e resolver problemas de deadlock no PostgreSQL.
