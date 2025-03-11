## Gerenciando o Serviço PostgreSQL: Parada, Reinício e Recarregamento de Configuração

Este guia detalha os diferentes modos de parada do PostgreSQL (smart, fast, immediate), além de comandos para reiniciar o serviço, recarregar a configuração e obter o status do serviço.

### Modos de Parada do PostgreSQL

O PostgreSQL oferece diferentes modos de parada, tanto via psql quanto via sistema operacional:

**Modos via psql (`pg_ctl`):**

* `Smart`: Parada segura, aguardando término de backups, transações e sessões.
* `Fast`: Encerramento forçado de backups, rollback de transações e fechamento de sessões.
* `Immediate`: Encerramento abrupto, semelhante a desligar o servidor, com risco de corrupção de dados.

**Modos via Sistema Operacional:**

* `Kill`: Encerramento forçado do processo, sem garantia de integridade.

### Comandos para Gerenciar o Serviço PostgreSQL

**1. Parada do Serviço (Modo Padrão: Smart):**

```bash
pg_ctl -D /dir/cluster stop
```

**2. Parada do Serviço (Modos Específicos):**

```bash
pg_ctl -m [modo] -D /dir/cluster stop
```

Onde `[modo]` pode ser:

* `smart`
* `fast`
* `immediate`

**3. Reinício do Serviço (Modos Específicos):**

```bash
pg_ctl -m [modo] -D /dir/cluster restart
```

Onde `[modo]` pode ser:

* `smart`
* `fast`
* `immediate`

**4. Recarregamento da Configuração:**

```bash
pg_ctl -D /dir/cluster reload
```

**5. Parada, Início e Status via `systemctl`:**

```bash
systemctl stop postgres
systemctl start postgres
systemctl status postgres
```

### Explicação dos Modos de Parada

* **Parada Smart:**
    * Modo mais seguro.
    * Aguarda a conclusão de backups, transações e encerramento de todas as sessões.
* **Parada Fast:**
    * Encerra backups, realiza rollback de transações e fecha sessões.
* **Parada Immediate:**
    * Encerramento abrupto, com risco de corrupção de dados.
    * Semelhante a desligar o servidor.

### Utilizando `pg_ctl`

**1. Localizando o Binário `pg_ctl`:**

Utilize o comando `ps`:

```bash
ps -ef | grep postgres
```

O binário `pg_ctl` geralmente está no diretório `bin` do PostgreSQL.

**2. Comandos `pg_ctl` (Exemplos):**

* Parada:

    ```bash
    /usr/lib/postgresql/14/bin/pg_ctl -D /var/lib/postgresql/14/main stop
    ```

* Início (Necessário apontar para `postgresql.conf`):

    ```bash
    /usr/lib/postgresql/14/bin/pg_ctl -D /etc/postgresql/14/main/ start
    ```

* Status:

    ```bash
    /usr/lib/postgresql/14/bin/pg_ctl -D /etc/postgresql/14/main/ status
    ```

* Parada Fast:

    ```bash
    /usr/lib/postgresql/14/bin/pg_ctl stop -D /var/lib/postgresql/14/main -m fast
    ```

* Parada Immediate:

    ```bash
    /usr/lib/postgresql/14/bin/pg_ctl stop -D /var/lib/postgresql/14/main -m immediate
    ```

* Parada Smart (Padrão):

    ```bash
    /usr/lib/postgresql/14/bin/pg_ctl stop -D /var/lib/postgresql/14/main -m smart
    ```

* Stop pg15

```bash
/usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/15/main/ stop
```
