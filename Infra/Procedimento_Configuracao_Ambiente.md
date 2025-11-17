## 📄 Sumário do Procedimento PostgreSQL

Este guia abrange as etapas essenciais para configurar um novo ambiente PostgreSQL, desde a preparação do sistema de arquivos até a criação de tabelas e índices em *tablespaces* dedicadas.

1.  **Preparação de Diretórios e Permissões**
2.  **Geração de Porta Aleatória (Opcional)**
3.  **Configuração de Parâmetros (pgtune)**
      * *Sugestões de Parâmetros Essenciais*
4.  **Configuração de Arquivamento (WAL Archives)**
5.  **Criação e Verificação de Tablespaces**
6.  **Criação de Usuário Proprietário (Owner) e Banco de Dados**
7.  **Organização via Schema Aplicacional (sentinelapp)**
      * *Configuração do Search Path (Caminho de Busca)*
      * *Validação do Search Path*
8.  **Teste de Criação de Tabela e Índice com Tablespaces**
      * *Verificação de Alocação de Tablespace*
      * *Exemplo de Alocação Específica (PK)*

-----

## 🛠️ Procedimento Didático de Configuração e Teste no PostgreSQL

Este procedimento é fundamental para garantir uma **organização** e **performance** melhores, separando dados, índices e archives.

### 1\. Preparação de Diretórios e Permissões

Antes de iniciar, crie os diretórios que serão usados para armazenar dados e índices em *tablespaces* separadas e ajuste as permissões para o usuário `postgres`.

| Comando | Descrição |
| :--- | :--- |
| `chown postgres:postgres /data/tbs_data` | Define `postgres` como proprietário do diretório de dados. |
| `chown postgres:postgres /index/tbs_index` | Define `postgres` como proprietário do diretório de índices. |
| `chmod 700 /data/tbs_data` | Permissão estrita (apenas o proprietário pode acessar). |
| `chmod 700 /index/tbs_index` | Permissão estrita para o diretório de índices. |

### 2\. Geração de Porta Aleatória (Opcional)

Gere uma porta aleatória para o PostgreSQL (útil em ambientes com múltiplos clusters).

```bash
shuf -i 1024-65535 -n 1
# Exemplo de saída: 64165
```

### 3\. Configuração de Parâmetros (pgtune)

Otimize os parâmetros do `postgresql.conf` para melhor desempenho. A ferramenta **pgtune** é sugerida como ponto de partida:

> **Link Sugerido:** [https://pgtune.leopard.in.ua/...](https://pgtune.leopard.in.ua/?dbVersion=17&osType=linux&dbType=oltp&cpuNum=4&totalMemory=8&totalMemoryUnit=GB&connectionNum=500&hdType=ssd)

| Parâmetro | Valor Sugerido (Exemplo de 8GB RAM, 4 CPUs, SSD, 500 conexões) |
| :--- | :--- |
| `max_connections` | `500` |
| `shared_buffers` | `2GB` |
| `effective_cache_size` | `6GB` |
| `maintenance_work_mem` | `512MB` |
| `checkpoint_completion_target` | `0.9` |
| `effective_io_concurrency` | `200` |
| `work_mem` | `4161kB` |
| `max_wal_size` | `8GB` |

### 4\. Configuração de Arquivamento (WAL Archives)

Crie e prepare o diretório para arquivamento dos **Write-Ahead Logs (WAL)**, essencial para recuperação de desastres (PITR).

```bash
sudo mkdir -p /archives/wal
sudo chown postgres:postgres /archives /archives/wal
sudo chmod 700 /archives /archives/wal
```

Para habilitar e configurar o arquivamento de WAL (Write-Ahead Log), os seguintes parâmetros no arquivo postgresql.conf precisam ser modificados:
```ìnit
# Configurações de Arquivamento (Archiving)
archive_mode = on           # Habilita o arquivamento contínuo
archive_command = 'cp %p /archives/wal/%f'  # Comando para arquivar os segmentos WAL. O caminho /archives/wal/ deve existir e ter permissões (como você já fez na etapa 4).
```

### 5\. Criação e Verificação de Tablespaces

As *tablespaces* permitem separar fisicamente dados e índices em diferentes locais do disco.

1.  **Criação:**

    ```sql
    CREATE TABLESPACE tbs_data LOCATION '/data/tbs_data';
    CREATE TABLESPACE tbs_index LOCATION '/index/tbs_index';
    ```

2.  **Verificação (no psql):**

    ```sql
    \db
    ```

    | Nome da Tablespace | Proprietário | Localização |
    | :--- | :--- | :--- |
    | `tbs_data` | `postgres` | `/data/tbs_data` |
    | `tbs_index` | `postgres` | `/index/tbs_index` |

### 6\. Criação de Usuário Proprietário (Owner) e Banco de Dados

Crie um *role* dedicado para ser o proprietário do banco e, em seguida, crie o banco de dados principal, alocando-o na *tablespace* de dados.

1.  **Criação do Usuário Owner:**

    ```sql
    CREATE ROLE ow_sentinel_system WITH LOGIN PASSWORD 'canada_2026';
    ```

2.  **Criação do Banco de Dados:**

    ```sql
    CREATE DATABASE sentinel_db
        OWNER = ow_sentinel_system
        TABLESPACE = tbs_data;
    ```

### 7\. Organização via Schema Aplicacional (`sentinelapp`)

Utilizar um *schema* dedicado (não o `public`) é uma **boa prática de organização**, prevenindo a criação acidental de objetos no *schema* padrão.

1.  **Criação do Schema:**

    ```sql
    CREATE SCHEMA sentinelapp;
    ```

2.  **Configuração do Search Path (Caminho de Busca):**

    O `search_path` define a ordem em que o PostgreSQL procura por objetos (tabelas, funções, etc.) quando o *schema* não é explicitado. Você pode defini-lo em três níveis:

    | Nível de Configuração | Comando SQL | Efeito |
    | :--- | :--- | :--- |
    | **Sessão** (Temporário) | `SET search_path = sentinelapp;` | Apenas na sessão atual. |
    | **Banco de Dados** (Padrão para todos) | `ALTER DATABASE sentinel_db SET search_path = sentinelapp;` | Padrão para novas conexões neste BD. |
    | **Usuário** (Padrão para um usuário) | `ALTER ROLE user_reader SET search_path = sentinelapp;` | Padrão para novas conexões deste usuário. |

3.  **Criação de Usuário Leitor (Exemplo):**

    ```sql
    CREATE ROLE user_reader WITH LOGIN PASSWORD 'canada_2026';
    ALTER ROLE user_reader SET search_path = sentinelapp; -- Configurando o search_path
    ```

4.  **Validação do Search Path:**

      * **Validando na sessão atual:**
        ```sql
        SHOW search_path;
        ```
      * **Validando no Banco de Dados (`sentinel_db`):**
        ```sql
        SELECT
            d.datname,
            s.setconfig
        FROM pg_database d
        LEFT JOIN pg_db_role_setting s
            ON s.setdatabase = d.oid AND s.setrole = 0
        WHERE d.datname = 'sentinel_db';
        ```
        > **Resultado Esperado:** `{search_path=sentinelapp}`

-----

### 8\. Teste de Criação de Tabela e Índice com Tablespaces

Crie objetos no *schema* `sentinelapp`, direcionando explicitamente a tabela e o índice para suas respectivas *tablespaces*.

1.  **Criação da Tabela e Índice:**

    ```sql
    -- Tabela vai para a tbs_data
    CREATE TABLE produtos (
        id SERIAL PRIMARY KEY,
        nome TEXT,
        preco NUMERIC
    ) TABLESPACE tbs_data;

    -- Índice (separado) vai para a tbs_index
    CREATE INDEX idx_produtos_nome ON produtos (nome) TABLESPACE tbs_index;
    ```

2.  **Verificação de Alocação de Tablespace:**

    ```sql
    SELECT
        c.relname AS object_name,
        n.nspname AS schema_name,
        CASE c.relkind WHEN 'r' THEN 'table' WHEN 'i' THEN 'index' END AS object_type,
        COALESCE(t.spcname, tdb.spcname) AS tablespace
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
    JOIN pg_database d ON d.datname = current_database()
    LEFT JOIN pg_tablespace tdb ON tdb.oid = d.dattablespace
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
        AND c.relname IN ('produtos', 'idx_produtos_nome') -- Corrigido para os nomes criados
    ORDER BY object_type, schema_name, object_name;
    ```

    | `object_name` | `schema_name` | `object_type` | `tablespace` |
    | :--- | :--- | :--- | :--- |
    | `idx_produtos_nome` | `sentinelapp` | `index` | `tbs_index` |
    | `produtos` | `sentinelapp` | `table` | `tbs_data` |

3.  **Exemplo de Alocação Específica (Chave Primária):**

    Você pode definir a *tablespace* de um índice (como uma Primary Key) **dentro** da declaração `CREATE TABLE`.

    ```sql
    CREATE TABLE products (
        id bigserial NOT NULL,
        nome text NOT NULL,
        preco numeric,
        CONSTRAINT products_pkey PRIMARY KEY (id)
            USING INDEX TABLESPACE tbs_index -- PK (índice) vai para a tbs_index
    )
    TABLESPACE tbs_data; -- Tabela (dados) vai para a tbs_data
    ```
