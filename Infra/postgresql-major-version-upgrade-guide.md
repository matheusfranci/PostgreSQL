# 🔄 Upgrade do PostgreSQL 17 para 18 com `pg_upgrade` (RHEL/CentOS/Alma/Rocky)

Este guia descreve o procedimento completo para upgrade do **PostgreSQL 17.7** para **PostgreSQL 18.2** utilizando `pg_upgrade` em modo `--link`.

> ⚠️ **IMPORTANTE:** Sempre execute esse procedimento em ambiente homologado antes de aplicar em produção.

---

# 📌 1. Validação do Ambiente Atual

## 🔎 Verificar versão instalada

```sql
SELECT version();
```

Saída esperada:

```
PostgreSQL 17.7 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 15.2.1 20251022 (Red Hat 15.2.1-3), 64-bit
```

---

## 📁 Verificar diretório de dados

```sql
SHOW data_directory;
```

Saída esperada:

```
/var/lib/pgsql/17/data
```

---

## 📦 Verificar diretório dos binários

```
/usr/pgsql-17/bin
```

---

## 🔌 Validar extensões instaladas nos bancos

Dentro do `psql`:

```sql
\dx
```

Garanta que todas as extensões utilizadas estejam disponíveis também na versão 18.

---

# 💾 2. Backup (OBRIGATÓRIO)

Antes de qualquer ação, realize:

* Backup físico (base backup)
* Backup lógico (dump completo do cluster)
* Backup dos arquivos de configuração

---

## 🗂️ Backup Físico (Full)

> Ajuste diretório, usuário e porta conforme seu ambiente.

```bash
DATA=$(date +%F)
mkdir -p /data/backup/full/$DATA

pg_basebackup -h localhost -U backup_oper \
  -Ft -z \
  -D /data/backup/full/$DATA \
  -P -X stream
```

---

## 📄 Backup Lógico Completo

```bash
pg_dumpall -U backup_oper -h localhost > /data/dump/full/cluster_full.sql
```

---

## ⚙️ Backup dos Arquivos de Configuração

Copie para local seguro:

* `pg_hba.conf`
* `postgresql.conf`

> ⚠️ O `pg_upgrade` **não reescreve automaticamente esses arquivos** no novo cluster.

---

# 📦 3. Instalação do PostgreSQL 18

## 🔍 Verificar pacotes disponíveis

```bash
dnf search postgresql18
```

---

## ⛔ Parar PostgreSQL 17

```bash
sudo systemctl stop postgresql-17
```

---

## 📥 Instalar PostgreSQL 18

Instalação básica:

```bash
sudo dnf install postgresql18-server postgresql18
```

Com extensões contrib:

```bash
sudo dnf install postgresql18-server postgresql18 postgresql18-contrib
```

---

# 🆕 4. Inicializar Cluster 18 (Pré-requisito)

> Não iniciar o serviço ainda.

```bash
/usr/pgsql-18/bin/initdb -D /var/lib/pgsql/18/data
```

---

# 🔎 5. Validar Versões Instaladas

```bash
/usr/pgsql-17/bin/postgres --version
```

```
postgres (PostgreSQL) 17.7
```

```bash
/usr/pgsql-18/bin/postgres --version
```

```
postgres (PostgreSQL) 18.2
```

---

# ✅ 6. Executar CHECK de Compatibilidade

> Ambos os clusters devem estar parados.

```bash
/usr/pgsql-18/bin/pg_upgrade \
  --old-datadir=/var/lib/pgsql/17/data \
  --new-datadir=/var/lib/pgsql/18/data \
  --old-bindir=/usr/pgsql-17/bin \
  --new-bindir=/usr/pgsql-18/bin \
  --check
```

---

## ⚠️ Atenção sobre CHECKSUM

O **PostgreSQL 18** vem com **checksum habilitado por padrão**, diferente do PostgreSQL 17.

Essa divergência pode fazer o `--check` falhar.

Documentação oficial:

* [https://www.postgresql.org/docs/17/checksums.html](https://www.postgresql.org/docs/17/checksums.html)
* [https://www.postgresql.org/docs/18/checksums.html](https://www.postgresql.org/docs/18/checksums.html)

---

## ✔️ Saída Esperada

```
*Clusters are compatible*
```

Se essa mensagem aparecer, os clusters estão aptos para upgrade.

---

# 🔍 7. Garantir que não há processos ativos

```bash
ps aux | grep postgres
```

Certifique-se de que não há instâncias em execução.

---

# 🚀 8. Executar Upgrade

```bash
/usr/pgsql-18/bin/pg_upgrade \
  --old-datadir=/var/lib/pgsql/17/data \
  --new-datadir=/var/lib/pgsql/18/data \
  --old-bindir=/usr/pgsql-17/bin \
  --new-bindir=/usr/pgsql-18/bin \
  --link
```

---

## ℹ️ Observação sobre `--link`

* Mais rápido
* Não copia arquivos, apenas cria hard links
* ⚠️ Após iniciar o cluster 18, o cluster 17 **não poderá ser iniciado com segurança**

---

## ✔️ Saída Esperada

```
Upgrade Complete
```

Ao final, será gerado:

```
./delete_old_cluster.sh
```

---

# 📊 9. Atualizar Estatísticas (Recomendado)

Após iniciar o novo cluster:

```bash
/usr/pgsql-18/bin/vacuumdb --all --analyze-in-stages --missing-stats-only
/usr/pgsql-18/bin/vacuumdb --all --analyze-only
```

---

# ▶️ 10. Subir PostgreSQL 18

```bash
sudo systemctl enable postgresql-18
sudo systemctl start postgresql-18
```

---

## 🔎 Validar Versão

```sql
SELECT version();
```

Saída esperada:

```
PostgreSQL 18.2 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 15.2.1 20260123 (Red Hat 15.2.1-7), 64-bit
```

---

# 🔍 11. Validações Pós-Upgrade

Realize:

* ✅ Testes de aplicação
* ✅ Validação de extensões (`\dx`)
* ✅ Atualização de extensões (`ALTER EXTENSION ... UPDATE;`)
* ✅ Validação de tablespaces
* ✅ Verificação de parâmetros customizados
* ✅ Conferência de replication slots (se houver)

---

# 🧹 12. Remover Cluster Antigo

Após validação completa:

```bash
./delete_old_cluster.sh
```

---

# 🎯 Conclusão

O upgrade via `pg_upgrade` em modo `--link` é:

* 🔥 Muito mais rápido
* 📉 Com downtime reduzido
* 🔐 Seguro (desde que backup tenha sido realizado)
