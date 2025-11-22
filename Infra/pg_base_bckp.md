## 💾 Script de Backup Completo do PostgreSQL (Base Backup)

Este *script* utiliza o comando **`pg_basebackup`** para criar um *backup* completo (`full backup`) e consistente de uma instância do PostgreSQL.

-----

### 🚀 O Comando

O comando é executado no *shell* para iniciar o processo de *backup*:

```bash
DATA=$(date +%F)
mkdir -p /data/backup/full/$DATA
pg_basebackup -h localhost -p 64165 -U dba_bkp \
  -Ft -z \
  -D /data/backup/full/$DATA \
  -P -X stream
```

-----

### 🔧 Detalhamento dos Passos

1.  **Definição da Variável de Data:**

    ```bash
    DATA=$(date +%F)
    ```

      * A variável **`DATA`** é definida com a data atual no formato **`AAAA-MM-DD`** (ex: `2025-11-22`). Isso garante que cada *backup* seja salvo em um diretório único baseado na data.

2.  **Criação do Diretório de Destino:**

    ```bash
    mkdir -p /data/backup/full/$DATA
    ```

      * Cria recursivamente o diretório de destino onde o *backup* será armazenado. O *flag* **`-p`** garante que a pasta seja criada apenas se não existir. O caminho final será, por exemplo, `/data/backup/full/2025-11-22`.

3.  **Execução do `pg_basebackup`:**

    ```bash
    pg_basebackup -h localhost -p 64165 -U dba_bkp \
      -Ft -z \
      -D /data/backup/full/$DATA \
      -P -X stream
    ```

    | Opção | Descrição |
    | :--- | :--- |
    | **`-h localhost`** | Especifica o **host** do servidor PostgreSQL. |
    | **`-p 64165`** | Especifica a **porta** em que o servidor PostgreSQL está escutando. |
    | **`-U dba_bkp`** | Especifica o **usuário** que será usado para a conexão e *backup*. Este usuário deve ter privilégios de replicação (`REPLICATION` role). |
    | **`-Ft`** | Define o formato de saída como **`tar`** (em vez do formato *plain*). |
    | **`-z`** | **Comprime** o arquivo tar usando `gzip`. |
    | **`-D /path/...`** | Especifica o **diretório de destino** para a saída do *backup* (o diretório criado na etapa 2). |
    | **`-P`** | **Relata o progresso** enquanto o *backup* está sendo executado. |
    | **`-X stream`** | Inclui os arquivos de **WAL (Write-Ahead Log)** no *backup* usando o modo de *streaming*. Isso é essencial para garantir a recuperabilidade (PITR - Point-in-Time Recovery). |

-----

### ⚠️ Requisitos

  * O usuário **`dba_bkp`** deve existir no PostgreSQL e ter o atributo **`REPLICATION`** ativado.
  * A configuração do **`pg_hba.conf`** deve permitir que o usuário **`dba_bkp`** se conecte a partir do *host* onde o *script* está sendo executado e acesse o *service* de replicação (`replication`).
  * O diretório `/data/backup/full/` deve ter **permissões de escrita** para o usuário que executa o *script*.
