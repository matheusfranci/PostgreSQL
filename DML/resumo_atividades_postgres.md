# Resumo das Atividades em Execução no PostgreSQL

## Descrição

Este script SQL fornece um resumo das atividades em execução no PostgreSQL, agrupadas por usuário, banco de dados e estado. Ele exibe o usuário, o banco de dados, o estado atual, a contagem de atividades, a contagem de atividades cujo estado mudou há mais de 1 minuto e a contagem de atividades cujo estado mudou há mais de 1 hora.

## Query

```sql
SELECT
    COALESCE(usename, '** ALL users **') AS "User",
    COALESCE(datname, '** ALL databases **') AS "DB",
    COALESCE(state, '** ALL states **') AS "Current State",
    COUNT(*) AS "Count",
    COUNT(*) FILTER (WHERE state_change < NOW() - INTERVAL '1 minute') AS "State changed >1m ago",
    COUNT(*) FILTER (WHERE state_change < NOW() - INTERVAL '1 hour') AS "State changed >1h ago"
FROM pg_stat_activity
GROUP BY GROUPING SETS ((datname, usename, state), (usename, state), ())
ORDER BY
    usename IS NULL DESC,
    datname IS NULL DESC,
    2 ASC,
    3 ASC,
    COUNT(*) DESC;
```

## Explicação Detalhada

* **`pg_stat_activity`**: Esta visão do sistema contém informações sobre as atividades em execução no servidor PostgreSQL.
* **`COALESCE(usename, '** ALL users **') AS "User"`**: Exibe o nome do usuário ou '** ALL users **' se o usuário for nulo (para o resumo geral).
* **`COALESCE(datname, '** ALL databases **') AS "DB"`**: Exibe o nome do banco de dados ou '** ALL databases **' se o banco de dados for nulo (para o resumo geral).
* **`COALESCE(state, '** ALL states **') AS "Current State"`**: Exibe o estado atual da atividade ou '** ALL states **' se o estado for nulo (para o resumo geral).
* **`COUNT(*) AS "Count"`**: Conta o número de atividades em cada grupo.
* **`COUNT(*) FILTER (WHERE state_change < NOW() - INTERVAL '1 minute') AS "State changed >1m ago"`**: Conta o número de atividades cujo estado mudou há mais de 1 minuto.
* **`COUNT(*) FILTER (WHERE state_change < NOW() - INTERVAL '1 hour') AS "State changed >1h ago"`**: Conta o número de atividades cujo estado mudou há mais de 1 hora.
* **`GROUP BY GROUPING SETS ((datname, usename, state), (usename, state), ())`**: Agrupa os resultados por banco de dados, usuário e estado, e também fornece resumos por usuário e estado e um resumo geral.
* **`ORDER BY usename IS NULL DESC, datname IS NULL DESC, 2 ASC, 3 ASC, COUNT(*) DESC`**: Ordena os resultados para colocar os resumos gerais no topo e ordenar os outros resultados por banco de dados, estado e contagem de atividades.

## Exemplos de Uso

Esta query pode ser usada para:

* Obter uma visão geral rápida das atividades em execução no banco de dados.
* Identificar usuários ou bancos de dados com um grande número de atividades.
* Monitorar o estado das atividades e identificar atividades que estão em um estado por um longo período de tempo.
* Diagnosticar problemas de desempenho ou bloqueios.

## Considerações

* O uso de `GROUPING SETS` permite gerar vários níveis de resumo em uma única consulta.
* As colunas "State changed >1m ago" e "State changed >1h ago" podem ajudar a identificar atividades que estão bloqueadas ou em um estado de espera por um longo período de tempo.
* A ordenação facilita a análise dos resultados, colocando os resumos gerais no topo e ordenando os outros resultados por relevância.
* Os resultados com a coluna "User" e "DB" com os valores "** ALL users **" e "** ALL databases **" respectivamente, indicam o total geral de atividades, e os resultados com somente a coluna "User" com o valor "** ALL users **", indicam o total de atividades por estado.
