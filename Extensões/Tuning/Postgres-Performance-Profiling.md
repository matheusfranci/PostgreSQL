Aqui está o procedimento formatado em Markdown, com foco na didática e organização, ideal para documentação no GitHub.

# 📊 Guia de Instalação e Configuração para Monitoramento Avançado no PostgreSQL

Este guia detalha a instalação e configuração das extensões **`pg_stat_kcache`** e **`pg_profile`**, juntamente com o agendador **`pg_cron`**, para realizar um monitoramento completo e gerar relatórios de performance (reports) do seu banco de dados PostgreSQL.

-----

## 1\. Instalação das Extensões Necessárias

Algumas extensões (como `dblink` e `pg_stat_statements`) podem ser instaladas diretamente, enquanto outras (`pg_stat_kcache` e `pg_profile`) exigem compilação manual.

### 1.1. Instalação via SQL

Conecte-se ao banco de dados alvo e instale as extensões básicas:

```sql
\c database_name
CREATE EXTENSION IF NOT EXISTS dblink;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

### 1.2. Instalação de `pg_stat_kcache` (Via Código-Fonte)

Esta extensão é crucial para o `pg_profile`, pois adiciona estatísticas de cache do kernel.

```bash
# 1. Clonar e compilar
cd /tmp
git clone https://github.com/powa-team/pg_stat_kcache.git
cd pg_stat_kcache

# 2. Definir o PATH do PostgreSQL e instalar (ajuste /usr/pgsql-17 conforme sua versão)
export PATH=/usr/pgsql-17/bin:$PATH
make
sudo PATH=$PATH make install
```

### 1.3. Instalação de `pg_cron` (Via Código-Fonte)

Esta extensão será usada para automatizar a coleta de *samples* do `pg_profile`.

```bash
# 1. Clonar e compilar
cd /tmp
git clone https://github.com/citusdata/pg_cron.git
cd pg_cron

# 2. Compilar e instalar
make
sudo PATH=$PATH make install
```

### 1.4. Instalação de `pg_profile` (Via Código-Fonte)

O `pg_profile` é a ferramenta principal para gerar os relatórios de comparação de performance.

```bash
# 1. Baixar e extrair
cd /tmp
wget https://github.com/zubkov-andrei/pg_profile/archive/refs/tags/4.10.tar.gz -O pg_profile-4.10.tar.gz
tar xzf pg_profile-4.10.tar.gz
cd pg_profile-4.10

# 2. Compilar e instalar (ajuste /usr/pgsql-17 conforme sua versão)
sudo make USE_PGXS=y PG_CONFIG=/usr/pgsql-17/bin/pg_config install

# 3. Criar diretórios e copiar arquivos de controle e SQL
/usr/bin/mkdir -p '/usr/pgsql-17/share/extension'
/usr/bin/install -c -m 644 pg_profile.control '/usr/pgsql-17/share/extension/'
/usr/bin/install -c -m 644 pg_profile--4.10.sql '/usr/pgsql-17/share/extension/'
```

-----

## 2\. Configuração do `postgresql.conf`

Após instalar os módulos, é necessário configurar o arquivo `postgresql.conf` para carregar as bibliotecas e habilitar as estatísticas necessárias.

Edite o arquivo `postgresql.conf` e adicione ou modifique as seguintes linhas:

```ini
#------------------------------------------------------------------------------
# CUSTOMIZED OPTIONS
#------------------------------------------------------------------------------

# Carrega as bibliotecas na inicialização do servidor
shared_preload_libraries = 'pg_hint_plan, pg_stat_monitor, pg_cron, pg_stat_statements, pg_stat_kcache'


# -------------------------------
# PostgreSQL Statistics Settings
# -------------------------------

track_activities = on           # Rastreia queries ativas por sessão
track_counts = on               # Habilita contadores de uso de tabela/índice
track_io_timing = off           # Opg_profile não exige este, mas pode ser útil para outros perfis
track_functions = pl            # Rastreia funções PL/pgSQL
track_activity_query_size = 2048 # Tamanho máximo da query rastreada


# -------------------------------
# pg_profile Settings
# -------------------------------

pg_profile.topn = 20                   # Quantidade de objetos (statements, tables) nos reports
pg_profile.max_sample_age = 7          # Retenção de samples em dias (limpeza automática)
pg_profile.track_sample_timings = off  # Detalhes de coleta de samples (opcional, p/ debug)
pg_profile.max_query_length = 20000    # Tamanho máximo de query mostrado nos reports

# -------------------------------
# pg_cron activation for a specific database
# -------------------------------
cron.database_name = 'database_name' # O pg_cron será ativado apenas neste DB
```

> **IMPORTANTE:** Após a edição, você deve **reiniciar o servidor PostgreSQL** para que as novas bibliotecas sejam carregadas.

-----

## 3\. Ativação Final e Coleta de Samples

Com o servidor reiniciado, você pode finalizar a ativação e iniciar a coleta de dados de performance.

### 3.1. Criar Extensões e Schema no Banco de Dados

Conecte-se ao banco de dados alvo e crie as extensões `pg_cron`, `pg_stat_kcache` e o `pg_profile` em um schema separado (`profile`):

```sql
\c database_name
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_stat_kcache;

CREATE SCHEMA profile;
CREATE EXTENSION pg_profile SCHEMA profile;
```

### 3.2. Coleta Manual de Samples

O `pg_profile` coleta dados em momentos específicos. Vamos tirar um **primeiro *sample*** para servir como linha de base:

```sql
SELECT profile.take_sample();
```

### 3.3. Gerar Atividade e Coletar o Segundo Sample

Simule uma carga de trabalho intensa para gerar dados de performance que serão comparados:

```bash
# Executar a ferramenta de benchmark pgbench (aumente ou diminua -s conforme a necessidade)
pgbench -i -s 1000 database_name
```

Após o benchmark, tire o **segundo *sample***:

```sql
SELECT profile.take_sample();
```

-----

## 4\. Geração do Relatório de Performance

O relatório compara as estatísticas coletadas entre dois *samples* (momentos).

### 4.1. Consultar IDs dos Samples

Recupere os `sample_id` e `sample_time` dos dois momentos que você deseja comparar:

```sql
SELECT sample_id, sample_time
FROM profile.samples
ORDER BY sample_id DESC;
```

**Exemplo de Saída:**

| sample\_id | sample\_time |
| :--- | :--- |
| **2** | 2025-10-16 02:09:57-03 |
| **1** | 2025-10-16 02:02:55-03 |

### 4.2. Gerar o Relatório HTML

Use os IDs obtidos (`1` e `2` no exemplo) para gerar o relatório e salvá-lo em um arquivo HTML:

```bash
# Sintaxe: psql -d [nome_do_banco] -Aqtc "SELECT profile.get_report([ID_INICIAL],[ID_FINAL]);" -o [nome_do_arquivo]
psql -d database_name -Aqtc "SELECT profile.get_report(1,2);" -o /tmp/report_1_2.html
```

-----

## 5\. Agendamento Automático de Samples com `pg_cron`

Para monitorar continuamente, você pode agendar a coleta de *samples* em intervalos regulares.

### 5.1. Agendar a Coleta a Cada Minuto

Crie um *job* com o `pg_cron` para executar `profile.take_sample()` a cada minuto:

```sql
SELECT cron.schedule(
    'pg_profile_snapshot',       -- nome do job
    '* * * * *',                 -- intervalo (a cada minuto)
    $$SELECT profile.take_sample();$$  -- comando SQL
);
```

### 5.2. Solução de Problemas (`connection failed`)

Se encontrar o erro "connection failed", geralmente significa que o `pg_cron` não sabe onde executar o *job*. Corrija setando o campo `nodename` do *job* para vazio (`''`), forçando-o a rodar no mesmo nó do banco de dados (localhost):

```sql
-- Supondo que o ID do seu job seja 2 (verifique em cron.job)
UPDATE cron.job SET nodename = '';
```

> O campo `cron.job.nodename` define o servidor onde o `pg_cron` deve executar o job. Ao deixar vazio, ele executa no mesmo nó onde o PostgreSQL está ativo.

### 5.3. Verificar Novos Samples Agendados

Após alguns minutos, verifique se novos *samples* foram coletados:

```sql
SELECT sample_id, sample_time
FROM profile.samples
ORDER BY sample_id DESC;
```

Segue exemplo gerado em meu drive, abra pelo navegador o HTML
https://drive.google.com/file/d/1VhtMaWC8e-ZBrFXAaF8pHuDwiDUYfUCy/view?usp=drive_link

Com o agendamento em vigor, você pode gerar relatórios comparando janelas de tempo específicas, como, por exemplo, um período de lentidão relatado por um usuário. Lembre-se de **agendar a coleta com janelas estratégicas** para evitar sobrecarga e ter dados relevantes.
