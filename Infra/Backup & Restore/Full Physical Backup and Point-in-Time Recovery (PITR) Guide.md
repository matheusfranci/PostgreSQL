# 🔄 Backup Full + PITR no PostgreSQL 18

Este guia demonstra como realizar:

* ✅ Backup físico full com `pg_basebackup`
* ✅ Configuração para **PITR (Point-In-Time Recovery)**
* ✅ Processo completo de restore
* ✅ Validação pós-recuperação
* ✅ Limpeza final

---

# 📌 1. Criando Banco para Teste

Antes do backup, criamos um banco apenas para validar o restore posteriormente.

```sql
CREATE DATABASE full;
```

# 💾 2. Realizando Backup Full

## 📂 Definindo variáveis

```bash
DATA=$(date +%F)
BACKUP_DIR=/data/backup/full/$DATA
mkdir -p $BACKUP_DIR
chown postgres:postgres $BACKUP_DIR  # Opcional, mas recomendado
```

## 🚀 Executando o pg_basebackup

```bash
sudo -u postgres pg_basebackup -h localhost -U bkp_agent \
-Ft -z \
-D $BACKUP_DIR \
-P -X stream -R
```

### 📌 Explicação dos parâmetros importantes:

| Parâmetro   | Função                               |
| ----------- | ------------------------------------ |
| `-Ft`       | Formato tar                          |
| `-z`        | Compacta o backup                    |
| `-X stream` | Inclui WAL via streaming             |
| `-R`        | Gera configuração básica de recovery |
| `-P`        | Mostra progresso                     |

## 🔎 Validação do Backup

```bash
if [ $? -eq 0 ]; then
  echo "Backup completed successfully in $BACKUP_DIR"
else
  echo "Backup error!"
fi
```

# ⚙️ 3. Parâmetros Necessários para PITR

No `postgresql.conf`, configure:

```conf
wal_level = replica
archive_mode = on
archive_command = 'test ! -f /data/backup/log/%f && cp %p /data/backup/log/%f'
```

### 📌 O que isso faz?

* `wal_level = replica` → Permite replicação e PITR
* `archive_mode = on` → Ativa arquivamento de WAL
* `archive_command` → Copia WAL para diretório seguro

---

# 🧪 4. Criando Banco para Simular PITR

```sql
CREATE DATABASE pitr;
```

## 🔄 Forçando geração de WAL

```sql
SELECT pg_switch_wal();
```

## 🔎 Validar arquivamento

```bash
ls -lisah /data/backup/log/
```


# ♻️ 5. Processo de Restore


## 🛑 5.1 Parar o Serviço

```bash
/usr/pgsql-18/bin/pg_ctl stop -D /var/lib/pgsql/18/data
```

## ⚠️ 5.2 Preparar Diretórios

### Opção 1 – Remover (CUIDADO)

```bash
rm -rf /var/lib/pgsql/18/data/*
rm -rf /data/tbs_data/*
rm -rf /data/tbs_index/*
```

### Opção 2 – Renomear (Mais Seguro)

```bash
mv /var/lib/pgsql/18/data /var/lib/pgsql/18/data_OLD_$(date +%F_%H%M)
mkdir /var/lib/pgsql/18/data

mv /data/tbsdata /data/tbsdata_OLD_$(date +%F_%H%M)
mkdir /data/tbsdata

mv /index/tbsidx /index/tbsidx_OLD_$(date +%F_%H%M)
mkdir /index/tbsidx
```

## 📦 5.3 Restaurar Backup

```bash
BACKUP_DIR="/data/backup/full/2026-02-21"  # Ajustar data
PGDATA="/var/lib/pgsql/18/data"
```

### Extrair base principal

```bash
tar -xzf $BACKUP_DIR/base.tar.gz -C $PGDATA
```

### Extrair Tablespaces

```bash
tar -xzf $BACKUP_DIR/16388.tar.gz -C /data/tbsdata
tar -xzf $BACKUP_DIR/16389.tar.gz -C /index/tbsidx
```

### Restaurar WAL

```bash
mkdir -p $PGDATA/pg_wal
tar -xzf $BACKUP_DIR/pg_wal.tar.gz -C $PGDATA/pg_wal/
```

---

## 🔐 5.4 Ajustar Permissões

```bash
chown -R postgres:postgres $PGDATA /data/tbsdata /index/tbsidx
chmod 700 $PGDATA /data/tbsdata /index/tbsidx
```

---

# 🧭 6. Configuração do Recovery

Adicionar no:

```
$PGDATA/postgresql.auto.conf
```

```bash
echo "restore_command = 'cp /data/backup/log/%f %p'" >> $PGDATA/postgresql.auto.conf
echo "recovery_target_time = '2026-02-21 03:40:00'" >> $PGDATA/postgresql.auto.conf
```

Criar arquivo sinalizador:

```bash
touch $PGDATA/recovery.signal
chown postgres:postgres $PGDATA/postgresql.auto.conf $PGDATA/recovery.signal
chmod 600 $PGDATA/postgresql.auto.conf
```

---

# 🚀 7. Iniciando PostgreSQL

```bash
/usr/pgsql-18/bin/pg_ctl -D /var/lib/pgsql/18/data start
```

---

# ✅ 8. Validando Restore

## 🔎 Verificar se ainda está em recovery

```sql
SELECT pg_is_in_recovery();
```

Resultado esperado após concluir:

```
 pg_is_in_recovery
-------------------
 f
```


## 📄 Validar Logs

```bash
vi /var/lib/pgsql/18/data/log/postgresql-Sat.log
```

### Mensagens esperadas:

```
LOG:  Archive recovery is complete
LOG:  checkpoint starting: end-of-recovery immediate wait
LOG:  checkpoint complete
LOG:  Database system is ready to accept connections
```

# 🧹 9. Limpeza Pós-Recovery

Remover arquivos antigos:

```bash
rm $PGDATA/backup_label.old
rm $PGDATA/tablespace_map.old
```

Remover parâmetros de recovery do:

```
postgresql.auto.conf
```

Apagar:

```conf
restore_command
recovery_target_time
```

# 🎯 Conclusão

Este procedimento cobre:

* Backup físico completo
* Arquivamento contínuo de WAL
* Restore manual
* Recuperação até ponto específico no tempo
* Validação final
