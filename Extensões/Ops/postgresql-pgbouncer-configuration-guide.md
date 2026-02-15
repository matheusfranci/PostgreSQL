# 🚀 Instalação e Configuração do PgBouncer com PostgreSQL (SCRAM-SHA-256)

# 📦 1. Instalação do PgBouncer

Instale o PgBouncer via `dnf`:

```bash
sudo dnf install pgbouncer -y
```

Verifique a versão instalada:

```bash
pgbouncer --version
```

Exemplo de saída:

```
PgBouncer 1.25.1
libevent 2.1.12-stable
adns: evdns2
tls: OpenSSL 3.2.4 11 Feb 2025
systemd: yes
```

---

# ⚙️ 2. Configuração do PgBouncer

Arquivo principal de configuração:

```bash
/etc/pgbouncer/pgbouncer.ini
```

## 🔹 Configuração utilizada

```ini
[databases]
bench = host=127.0.0.1 port=5432 dbname=bench

[users]

[pgbouncer]
logfile = /var/log/pgbouncer/pgbouncer.log
pidfile = /var/run/pgbouncer/pgbouncer.pid
listen_addr = localhost
listen_port = 6432
pool_mode = transaction
max_client_conn = 2000
default_pool_size = 150
log_connections = 1
log_disconnections = 1
log_pooler_errors = 1
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt
admin_users = postgres
stats_users = stats, postgres
reserve_pool_size = 20
reserve_pool_timeout = 5
```

---

## 🧠 Entendendo os principais parâmetros

| Parâmetro                   | Descrição                                            |
| --------------------------- | ---------------------------------------------------- |
| `pool_mode = transaction`   | Conexões são reutilizadas ao final de cada transação |
| `max_client_conn = 2000`    | Máximo de conexões clientes simultâneas              |
| `default_pool_size = 150`   | Conexões ativas mantidas para o banco                |
| `reserve_pool_size = 20`    | Conexões extras para picos                           |
| `auth_type = scram-sha-256` | Método de autenticação seguro                        |

---

# 🔐 3. Configurando autenticação SCRAM-SHA-256

O PgBouncer **não armazena senhas em texto plano** quando configurado com `scram-sha-256`.
É necessário extrair o hash diretamente do PostgreSQL.

## 🔎 Dentro do PostgreSQL

Execute:

```sql
SELECT rolname, rolpassword
FROM pg_authid
WHERE rolname = 'postgres';
```

Exemplo de retorno:

```
rolname  | SCRAM-SHA-256$4096:cPmbLkWnGF16YXoqlUCJ7w==$+vMOLfshCIzSGSkczTUBMo3cz6ydVH84UW59lEHP1Us=:lPcJeVFigsYWA5BOCN1uDbq3Fg+PR91enZHZ00Mr7j8=
```

---

## ✏️ Editando o arquivo de usuários do PgBouncer

```bash
sudo vi /etc/pgbouncer/userlist.txt
```

Adicione no formato:

```txt
"postgres" "SCRAM-SHA-256$4096:cPmbLkWnGF16YXoqlUCJ7w==$+vMOLfshCIzSGSkczTUBMo3cz6ydVH84UW59lEHP1Us=:lPcJeVFigsYWA5BOCN1uDbq3Fg+PR91enZHZ00Mr7j8="
```

---

## 🔒 Ajustando permissões

```bash
sudo chown pgbouncer:pgbouncer /etc/pgbouncer/userlist.txt
sudo chmod 600 /etc/pgbouncer/userlist.txt
```

---

# 🔥 4. Liberando porta no firewall

```bash
sudo firewall-cmd --add-port=6432/tcp --permanent
sudo firewall-cmd --reload
```

Porta utilizada pelo PgBouncer: **6432**

---

# 🟢 5. Habilitando e iniciando o serviço

```bash
sudo systemctl enable pgbouncer
sudo systemctl start pgbouncer
```

Verificando status:

```bash
sudo systemctl status pgbouncer
```

---

# 🔌 6. Validando conexão via PgBouncer

Teste a conexão usando `psql`:

```bash
psql -h 127.0.0.1 -p 6432 -U postgres bench
```

Se conectar corretamente, o pool está funcionando.

---

# 🧪 7. Testes de performance com pgbench

Ferramenta utilizada: `pgbench`

---

## 🔴 Teste sem PgBouncer (conectando direto na porta 5432)

```bash
pgbench -c 1000 -j 16 -T 120 -P 1 bench | tee sem_pool_1000.log
```

### Resultado:

```
number of transactions actually processed: 22520
latency average = 5345.987 ms
tps = 183.167833
```

---

## 🟢 Teste com PgBouncer (porta 6432)

```bash
pgbench -h 127.0.0.1 -p 6432 -U postgres -c 1000 -j 16 -T 120 -P 1 bench | tee com_pool_1000.log
```

### Resultado:

```
number of transactions actually processed: 29389
latency average = 4086.254 ms
tps = 239.136096
```

---

# 📊 8. Comparativo de Performance

| Métrica        | Sem Pool | Com Pool |
| -------------- | -------- | -------- |
| Transações     | 22.520   | 29.389   |
| Latência média | 5345 ms  | 4086 ms  |
| TPS            | 183      | 239      |

### 🎯 Ganho aproximado:

* **+30% de TPS**
* **Menor latência média**
* **Melhor estabilidade sob alta concorrência**

---

# 🏁 Conclusão

A implementação do **PgBouncer** com `pool_mode=transaction` e autenticação `SCRAM-SHA-256` trouxe:

* Redução significativa de latência
* Aumento de throughput (TPS)
* Melhor gerenciamento de conexões
* Maior escalabilidade

Essa configuração é altamente recomendada para ambientes com **alta concorrência** e grande volume de conexões simultâneas.
