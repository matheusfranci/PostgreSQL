# 🚀 Procedimento de Teste: Instalação e Uso do `pg_stat_monitor`

Este guia detalha a instalação da extensão `pg_stat_monitor` e apresenta consultas essenciais para identificar gargalos de desempenho (ofensores) no seu banco de dados PostgreSQL.

## 1\. Instalação e Configuração da Extensão

Siga os passos no terminal para baixar, compilar e instalar a extensão.

### 1.1. Download e Preparação

```bash
# Navega para o diretório /tmp
cd /tmp

# Clona o repositório oficial do pg_stat_monitor
git clone https://github.com/percona/pg_stat_monitor.git

# Entra no diretório da extensão clonada
cd pg_stat_monitor
```

### 1.2. Compilação da Extensão

**Atenção:** Certifique-se de ajustar o caminho do `PG_CONFIG` (aqui usamos `/usr/pgsql-17/bin/pg_config`) para a versão correta do seu PostgreSQL instalada.

```bash
# Compila a extensão usando as ferramentas do PostgreSQL
make USE_PGXS=1 PG_CONFIG=/usr/pgsql-17/bin/pg_config
```

### 1.3. Cópia dos Arquivos para o PostgreSQL

Copie os arquivos gerados para os diretórios de extensão e biblioteca do PostgreSQL. **Mantenha a atenção na versão (ex: `postgresql-17`)**.

```bash
# Copia o arquivo de controle
sudo cp pg_stat_monitor.control /usr/pgsql-17/share/extension/

# Copia os arquivos de script SQL
sudo cp pg_stat_monitor--*.sql /usr/pgsql-17/share/extension/

# Copia a biblioteca compartilhada (o coração da extensão)
sudo cp pg_stat_monitor.so /usr/pgsql-17/lib/
```

### 1.4. Ativação no `postgresql.conf`

Edite o arquivo de configuração principal do PostgreSQL (`postgresql.conf`) para carregar a biblioteca durante a inicialização.

1.  Abra o arquivo de configuração (localização pode variar).
2.  Localize a variável `shared_preload_libraries` e adicione `'pg_stat_monitor'`.

<!-- end list -->

```conf
# Exemplo de configuração no postgresql.conf
shared_preload_libraries = 'pg_stat_monitor' 
```

### 1.5. Reinício do Serviço e Criação no Banco

Reinicie o serviço do PostgreSQL e, em seguida, conecte-se ao seu banco de dados para criar a extensão.

```bash
# Reinicia o serviço (ajuste a versão se necessário)
sudo systemctl restart postgresql-17
```

```sql
-- Conecte-se ao seu banco de dados (ex: 'qualitydb') e crie a extensão
CREATE EXTENSION pg_stat_monitor;
```

-----

## 2\. Geração de Massa de Dados e Estatísticas

Use a ferramenta `pgbench` para gerar uma carga de trabalho básica e popular o banco de dados com estatísticas de consultas.

```bash
# Inicializa o pgbench com um fator de escala de 1000 no banco 'qualitydb'
pgbench -i -s 1000 qualitydb
```

-----

## 3\. Análise de Desempenho (Queries Ofensoras)

Com a extensão ativa e a carga de dados gerada, utilize as seguintes consultas no banco de dados para identificar gargalos de desempenho.

### 1️⃣ Top Queries por Tempo Total de Execução

Identifica as queries que, **acumuladamente**, mais consumiram recursos desde o início da coleta.

```sql
SELECT queryid,
       query,
       calls,
       total_exec_time,
       mean_exec_time
FROM pg_stat_monitor
ORDER BY total_exec_time DESC
LIMIT 10;
```

> 💡 **Foco:** O `queryid` e `query` ajudam a rastrear queries repetidas, mesmo com parâmetros diferentes.

### 2️⃣ Top Queries por Média de Tempo (As Mais Lentas)

Filtra as queries que são **mais lentas em média**, mesmo que não sejam chamadas muitas vezes.

```sql
SELECT queryid,
       query,
       calls,
       mean_exec_time,
       total_exec_time
FROM pg_stat_monitor
ORDER BY mean_exec_time DESC
LIMIT 10;
```

> 💡 **Foco:** Ideal para identificar pontos críticos de performance em operações pontuais.

### 3️⃣ Análise Agrupada por Usuário e Banco de Dados

Permite ver qual **usuário** e qual **banco de dados** estão gerando a maior carga de trabalho e tempo de execução total.

```sql
SELECT userid,
       datname,
       SUM(calls) AS total_calls,
       SUM(total_exec_time) AS total_time,
       AVG(mean_exec_time) AS avg_time
FROM pg_stat_monitor
GROUP BY userid, datname
ORDER BY total_time DESC;
```

### 4️⃣ Análise por Tipo de Comando (Tag)

Mostra quais tipos de operação (`SELECT`, `UPDATE`, `INSERT`, `DELETE`) estão consumindo mais tempo.

```sql
SELECT command_tag,
       COUNT(*) AS count_queries,
       SUM(total_exec_time) AS total_time,
       AVG(mean_exec_time) AS avg_time
FROM pg_stat_monitor
GROUP BY command_tag
ORDER BY total_time DESC;
```

> 💡 **Foco:** Bom para analisar a carga de OLTP (Online Transaction Processing) no seu banco.

### 5️⃣ Queries que Geraram Erro

Monitora queries problemáticas ou falhas repetidas.

```sql
SELECT queryid,
       planid,
       query,
       calls,
       total_exec_time,
       mean_exec_time,
       message
FROM pg_stat_monitor
WHERE message IS NOT NULL
  AND message ILIKE '%error%'
ORDER BY total_exec_time DESC
LIMIT 20;
```

### 6️⃣ Comparação de Planos de Execução (Plan Variance)

Identifica a mesma query que está sendo executada com **múltiplos planos de execução** diferentes.

```sql
WITH plan_variants AS (
    SELECT query
    FROM pg_stat_monitor
    WHERE planid IS NOT NULL
    GROUP BY query
    HAVING COUNT(DISTINCT planid) > 1
)
SELECT p.query,
       p.planid,
       p.calls,
       p.total_exec_time,
       p.mean_exec_time
FROM pg_stat_monitor p
JOIN plan_variants pv
  ON p.query = pv.query
WHERE p.planid IS NOT NULL
ORDER BY p.total_exec_time DESC
LIMIT 20;
```

> 💡 **Foco:** Essencial para diagnosticar instabilidade. Se o plano da mesma query mudar e a performance cair, você verá rapidamente aqui.
