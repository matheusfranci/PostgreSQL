# ⚙️ Procedimento de Teste de Backup e Restauração com pgBackRest

Este guia detalha a instalação, configuração e execução de backups (Full e Incremental) e um teste de restauração utilizando o pgBackRest no PostgreSQL.

## 1\. Instalação do pgBackRest

Use o gerenciador de pacotes `dnf` (comum em sistemas RHEL/Fedora/CentOS) para instalar a ferramenta.

```bash
sudo dnf install pgbackrest
```

## 2\. Configuração de Diretórios

O pgBackRest precisa de um diretório para seus arquivos de configuração e outro para armazenar os backups (o **repositório**).

### A. Diretório de Configuração

Crie e ajuste as permissões para que o usuário **`postgres`** seja o proprietário, garantindo segurança.

```bash
# 1. Crie o diretório de configuração
sudo mkdir -p /etc/pgbackrest

# 2. Defina o usuário 'postgres' como proprietário
sudo chown postgres:postgres /etc/pgbackrest

# 3. Defina permissões restritas (dono: leitura/escrita/execução, grupo: leitura/execução)
sudo chmod 750 /etc/pgbackrest
```

### B. Diretório do Repositório de Backup

Crie o diretório onde os backups e arquivos WAL serão armazenados.

```bash
# 1. Crie o diretório do repositório
sudo mkdir -p /pg01/backup

# 2. Defina o usuário 'postgres' como proprietário
sudo chown postgres:postgres /pg01/backup

# 3. Defina permissões restritas (dono: leitura/escrita/execução, grupo: leitura/execução)
sudo chmod 750 /pg01/backup
```

## 3\. Configuração do pgBackRest (pgbackrest.conf)

Crie o arquivo de configuração principal em `/etc/pgbackrest/pgbackrest.conf`.

Este arquivo define:

1.  O **repositório** (`repo1-path`).
2.  A **política de retenção** (`repo1-retention-full`).
3.  A **stanza** (nome lógico da instância, `[main]`).
4.  O caminho do **diretório de dados** do PostgreSQL (`pg1-path`).

### Conteúdo do `/etc/pgbackrest/pgbackrest.conf`

```ini
# =====================================================================
# ARQUIVO DE CONFIGURAÇÃO DO pgBackRest
# Caminho: /etc/pgbackrest/pgbackrest.conf
# =====================================================================

[global]
# Caminho onde os backups e os arquivos de WAL arquivados serão armazenados.
# Esse diretório é conhecido como "repositório de backup".
repo1-path=/pg01/backup

# Quantos backups completos (full) o pgBackRest deve manter.
repo1-retention-full=2


[main]
# Nome lógico da instância (stanza).
# O nome 'main' é um identificador que você usará nos comandos.

# Caminho do diretório de dados do PostgreSQL (o mesmo de data_directory no postgresql.conf).
pg1-path=/var/lib/pgsql/17/data
```

### Ajuste de Permissões do Arquivo de Configuração

```bash
# 1. Defina o usuário 'postgres' como proprietário
sudo chown postgres:postgres /etc/pgbackrest/pgbackrest.conf

# 2. Permissão de leitura/escrita para o dono (postgres), leitura para o grupo
sudo chmod 640 /etc/pgbackrest/pgbackrest.conf
```

## 4\. Configuração do PostgreSQL

Para que o pgBackRest funcione, o PostgreSQL precisa ter o **arquivamento de WAL (Write-Ahead Log)** habilitado.

-----

**⚠️ Ação Necessária:** Edite o arquivo `postgresql.conf` e habilite/configure os seguintes parâmetros (pode ser necessário reiniciar o PostgreSQL).

```ini
# No postgresql.conf
archive_mode = on
archive_command = 'pgbackrest --stanza=main archive-push %p'
```

-----

## 5\. Criação e Validação da Stanza

Uma **stanza** é uma configuração lógica que associa o pgBackRest a uma instância específica do PostgreSQL.

### A. Criação da Stanza

O comando abaixo cria a estrutura da `stanza` no repositório de backup.

```bash
pgbackrest --stanza=main --log-level-console=info stanza-create
```

**Saída de Exemplo:**

```
2025-10-28 22:46:50.132 P00    INFO: stanza-create for stanza 'main' on repo1
2025-10-28 22:46:50.288 P00    INFO: stanza-create command end: completed successfully (176ms)
```

### B. Validação da Stanza

O comando `check` confirma se a configuração e o arquivamento de WAL estão funcionando corretamente.

```bash
pgbackrest --stanza=main --log-level-console=info check
```

**Saída de Exemplo:**

```
...
2025-10-28 22:47:36.159 P00    INFO: check repo1 archive for WAL (primary)
2025-10-28 22:47:36.260 P00    INFO: WAL segment 000000010000001B00000059 successfully archived...
2025-10-28 22:47:36.260 P00    INFO: check command end: completed successfully (149ms)
```

## 6\. Execução de Backups

O pgBackRest oferece diferentes tipos de backup, sendo **Full** e **Incremental** os mais comuns.

| Tipo | O que Salva | Como Restaura | Quando Usar |
| :--- | :--- | :--- | :--- |
| **Full (Completo)** | Todos os dados. | Só precisa deste backup. | Primeiro backup, semanal ou quinzenal. |
| **Incremental** | Só as mudanças desde o **último** backup (full ou incremental). | Precisa do **último full + todos os incrementais** subsequentes. | Backup diário, é rápido e economiza espaço. |

### A. Backup Full (Completo)

O primeiro backup sempre será `full`. O pgBackRest avisa sobre isso.

```bash
pgbackrest --stanza=main --log-level-console=info backup
```

**Saída de Exemplo (Onde o primeiro backup é Full):**

```
...
2025-10-28 22:49:50.696 P00    WARN: no prior backup exists, incr backup has been changed to full
...
2025-10-28 22:55:40.954 P00    INFO: full backup size = 26.8GB, file total = 2127
2025-10-28 22:55:40.954 P00    INFO: backup command end: completed successfully (350278ms)
```

### B. Backup Incremental

Use o parâmetro `--type=incr` para um backup que salve apenas as alterações desde o último backup.

```bash
pgbackrest --stanza=main --type=incr --log-level-console=info backup
```

**Saída de Exemplo (Incremental):**

```
...
2025-10-28 23:27:25.435 P00    INFO: new backup label = 20251028-224950F_20251028-232718I
2025-10-28 23:27:25.605 P00    INFO: incr backup size = 22.8MB, file total = 2127
2025-10-28 23:27:25.605 P00    INFO: backup command end: completed successfully (7271ms)
```

### C. Verificação de Informações de Backup

O comando `info` lista todos os backups e seus detalhes (tamanho, data/hora, etc.).

```bash
pgbackrest info
```

**Saída de Exemplo:**

```
stanza: main
    status: ok
    db (current)
        wal archive min/max (17): 000000010000001B00000058/000000010000001B0000005B

        full backup: 20251028-224950F
            timestamp start/stop: 2025-10-28 22:49:50-03 / 2025-10-28 22:55:40-03
            ...
            repo1: backup set size: 3.5GB, backup size: 3.5GB

        incr backup: 20251028-224950F_20251028-232718I  <-- O incremental criado
            timestamp start/stop: 2025-10-28 23:27:18-03 / 2025-10-28 23:27:25-03
            ...
            repo1: backup set size: 22.8MB, backup size: 22.8MB
```

-----

# 💾 Teste de Restauração

A restauração exige que o cluster do PostgreSQL seja parado e que o diretório de dados existente seja movido ou apagado.

## 1\. Preparação para Restauração

### A. Parar o PostgreSQL

```bash
sudo systemctl stop postgresql-17
```

### B. Fazer Backup/Mover Diretórios Existentes

É crucial mover o diretório de dados e qualquer **tablespace** para evitar a perda de dados e liberar o caminho para a restauração.

```bash
# Backup/Mova o diretório de dados principal
sudo mv /var/lib/pgsql/17/data /var/lib/pgsql/17/data.old

# (Se houver tablespace) Backup/Mova o tablespace
sudo mv /pg01/PG_17_202406281 /pg01/PG_17_202406281.old

# Recrie e ajuste permissões do diretório de dados (vazio)
sudo mkdir -p /var/lib/pgsql/17/data
sudo chown postgres:postgres /var/lib/pgsql/17/data
sudo chmod 700 /var/lib/pgsql/17/data

# Recrie e ajuste permissões do tablespace (se aplicável)
sudo mkdir -p /pg01/PG_17_202406281
sudo chown postgres:postgres /pg01/PG_17_202406281
sudo chmod 700 /pg01/PG_17_202406281
```

## 2\. Execução da Restauração

O comando `restore` com o pgBackRest é simples. Por padrão, ele restaura o **backup mais recente**, incluindo todos os incrementais ou diferenciais associados.

```bash
pgbackrest --stanza=main --log-level-console=info restore
```

**Saída de Exemplo:**

```
...
2025-10-28 23:35:18.558 P00    INFO: repo1: restore backup set 20251028-224950F_20251028-232718I, recovery will start at 2025-10-28 23:27:18
...
2025-10-28 23:36:39.339 P00    INFO: restore command end: completed successfully (80794ms)
```

## 3\. Finalização

### A. Iniciar o PostgreSQL

O PostgreSQL iniciará automaticamente o processo de recuperação (PITR), aplicando os WALs necessários.

```bash
sudo systemctl start postgresql-17
```

### B. Limpar Diretórios Antigos (Opcional)

Após confirmar que o PostgreSQL foi iniciado com sucesso e os dados estão corretos, você pode remover os diretórios antigos.

```bash
rm -rf /pg01/PG_17_202406281.old
rm -rf /var/lib/pgsql/17/data.old
```
