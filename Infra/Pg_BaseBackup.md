#### Passo 1: Parar e Limpar

```bash
# Parar o serviço
/usr/pgsql-17/bin/pg_ctl stop -D /var/lib/pgsql/17/data

# Limpar diretórios (Cuidado: verifique se está nas variáveis corretas)
rm -rf /var/lib/pgsql/17/data/*
rm -rf /data/tbs_data/*
rm -rf /data/tbs_index/*

# Também pode optar por renomear mas para isso é necessário ter certeza que há espaço suficiente para dois de cada, seguem comandos:
# Mover o atual para um nome de backup
mv /var/lib/pgsql/17/data /var/lib/pgsql/17/data_OLD_$(date +%F_%H%M)

# Recriar a pasta original vazia para receber o restore
mkdir /var/lib/pgsql/17/data

# Mover Tablespace DATA
mv /data/tbs_data /data/tbs_data_OLD_$(date +%F_%H%M)
mkdir /data/tbs_data

# Mover Tablespace INDEX
mv /data/tbs_index /data/tbs_index_OLD_$(date +%F_%H%M)
mkdir /data/tbs_index

# Ajustar dono
chown postgres:postgres /var/lib/pgsql/17/data
chown postgres:postgres /data/tbs_data
chown postgres:postgres /data/tbs_index

# Ajustar modo (apenas dono lê/escreve)
chmod 700 /var/lib/pgsql/17/data
chmod 700 /data/tbs_data
chmod 700 /data/tbs_index
```

#### Passo 2: Restaurar o Base Backup (Fundamental)

Primeiro restauramos a base para ler o arquivo de mapeamento.

```bash
# Definir variavel para facilitar
BACKUP_DIR="/data/backup/full/2025-11-21" # Ajuste para a data correta
PGDATA="/var/lib/pgsql/17/data"

# 1. Extrair a Base
tar -xzf $BACKUP_DIR/base.tar.gz -C $PGDATA
```

#### Passo 3: Verificar o Mapeamento das Tablespaces

**Antes** de extrair as tablespaces, verifique o arquivo que acabou de ser extraído:

```bash
cat $PGDATA/tablespace_map
```

*Saída esperada (exemplo):*

> 16388 /data/tbs\_data
> 16389 /data/tbs\_index

**Agora sim**, sabendo quem é quem, execute a extração:

```bash
# 2. Extrair Tablespaces (Confirme os OIDs com o cat acima!)
tar -xzf $BACKUP_DIR/16388.tar.gz -C /data/tbs_data/
tar -xzf $BACKUP_DIR/16389.tar.gz -C /data/tbs_index/
```

#### Passo 4: Restaurar os WALs (A Correção Principal)

O diretório `pg_wal` foi criado vazio pelo `base.tar.gz`. Agora enchemos ele:

```bash
# Certifique-se que a pasta existe (por segurança)
mkdir -p $PGDATA/pg_wal

# Extrair DENTRO de pg_wal
tar -xzf $BACKUP_DIR/pg_wal.tar.gz -C $PGDATA/pg_wal/
```

#### Passo 5: Permissões e Ajustes Finais

```bash
# Permissões (Tablespaces e Data Dir)
chown -R postgres:postgres $PGDATA /data/tbs_data /data/tbs_index
chmod 700 $PGDATA /data/tbs_data /data/tbs_index
```

#### Passo 6: Configuração de Recovery

Como você usou `-X stream` no backup, o `pg_wal` restaurado já contém os WALs necessários para tornar o backup consistente. O `restore_command` é opcional se você só quer subir o backup como estava no momento do término, mas é **obrigatório** se você quer fazer Point-in-Time Recovery (PITR) usando seus arquivos em `/archives/wal`.

Seu setup está correto para PITR:

```bash
# Adicionar configs
echo "restore_command = 'cp /archives/wal/%f %p'" >> $PGDATA/postgresql.auto.conf

# Arquivo de sinalização para o PG entrar em modo de recovery
touch $PGDATA/recovery.signal

# Permissões dos arquivos de config
chown postgres:postgres $PGDATA/postgresql.auto.conf $PGDATA/recovery.signal
chmod 600 $PGDATA/postgresql.auto.conf
```

#### Passo 7: Iniciar

```bash
/usr/pgsql-17/bin/pg_ctl start -D $PGDATA
```

### Como validar se funcionou

1.  **Verifique os logs imediatamente:**
    `tail -f /var/lib/pgsql/17/data/log/postgresql-....log`
      * Você deve ver mensagens como: *consistent recovery state reached* e *database system is ready to accept connections*.
