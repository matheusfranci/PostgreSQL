# 🚀 Procedimento de Teste: Instalação e Configuração do pgaudit no PostgreSQL 17

Este guia detalha os passos para compilar e instalar a extensão **`pgaudit`** a partir do código-fonte e verificar se o **log de auditoria** está funcionando corretamente.

-----

## 1\. Instalação e Compilação do pgaudit (Do Código-Fonte)

Estes passos utilizam comandos Linux (assumindo uma distribuição baseada em RPM, como Fedora/CentOS/RHEL, pelo uso do `dnf`).

### 1.1. Obter o Código-Fonte

Clone o repositório oficial do `pgaudit` e acesse o diretório.

```bash
git clone https://github.com/pgaudit/pgaudit.git
cd pgaudit
```

### 1.2. Selecionar o Branch Correto

É crucial usar o branch que é compatível com a sua versão do PostgreSQL (neste caso, v17).

```bash
# Verifique o branch compatível com PostgreSQL 17, por exemplo: REL_17_STABLE
git checkout REL_17_STABLE
```

### 1.3. Instalar Dependências e Compilar

Instale a dependência de desenvolvimento (krb5-devel) e, em seguida, compile a extensão usando as ferramentas do PostgreSQL.

```bash
# Instalar dependência
sudo dnf install krb5-devel

# Compilar a extensão
make USE_PGXS=1 PG_CONFIG=/usr/pgsql-17/bin/pg_config

# Instalar a extensão no diretório do PostgreSQL
sudo make install USE_PGXS=1 PG_CONFIG=/usr/pgsql-17/bin/pg_config
```

-----

## 2\. Configuração do PostgreSQL

Após a instalação binária, a extensão deve ser carregada pelo servidor.

### 2.1. Editar o `postgresql.conf`

Edite o arquivo de configuração principal (`postgresql.conf`) para incluir o `pgaudit` nas bibliotecas de pré-carregamento. Isso garante que a extensão seja inicializada antes que qualquer conexão de banco de dados seja estabelecida.

Localize a linha `shared_preload_libraries` e adicione `'pgaudit'`.

```conf
shared_preload_libraries = 'pgaudit'
# Se já houver outras bibliotecas, adicione separando por vírgula, por exemplo:
# shared_preload_libraries = 'outra_extensao, pgaudit'
```

### 2.2. Reiniciar o Serviço

O PostgreSQL precisa ser reiniciado para carregar as novas bibliotecas de pré-carregamento.

```bash
sudo systemctl restart postgresql.service
```

### 2.3. Habilitar a Extensão no Banco de Dados

Conecte-se ao banco de dados (como superuser) e crie a extensão.

```sql
-- Conecte-se ao psql (ou ferramenta de sua preferência)
psql -U postgres -d seu_banco_de_dados

-- Crie a extensão
CREATE EXTENSION pgaudit;
```

-----

## 3\. Teste de Auditoria e Verificação de Logs

Agora execute comandos SQL para gerar eventos de auditoria e verifique se eles estão sendo registrados no log do servidor.

### 3.1. Executar Comandos de Teste

Execute comandos que o `pgaudit` tipicamente rastreia (DDL e ROLEs).

```sql
-- Teste de DDL (Data Definition Language)
CREATE TABLE t_audit_test(col text);
ALTER TABLE t_audit_test ADD COLUMN col2 int;
DROP TABLE t_audit_test;

-- Teste de ROLE (Comandos de Usuário)
CREATE ROLE test_role;
ALTER ROLE test_role LOGIN;
DROP ROLE test_role;
```

### 3.2. Configuração Extra para Logs (Opcional, mas Recomendado)

Para facilitar a leitura e incluir informações cruciais (usuário e banco de dados) em cada linha de log, edite novamente o `postgresql.conf` e configure o `log_line_prefix`.

```conf
# Altere ou adicione esta linha:
log_line_prefix = '%m [%p] %u@%d '
```

**Lembre-se:** Após alterar o `log_line_prefix`, você deve **reiniciar** o PostgreSQL novamente:
`sudo systemctl restart postgresql.service`

### 3.3. Verificar os Logs (Exemplo)

Verifique o arquivo de log do PostgreSQL (o local varia, mas o caminho `/var/lib/pgsql/17/data/log/` é comum). Você deve encontrar linhas de log no formato **`AUDIT: SESSION, ...`**, como nos exemplos abaixo:

```log
2025-10-27 22:56:14.330 -03 [1936] postgres@qualitydb LOG:  AUDIT: SESSION,1,1,DDL,CREATE TABLE,TABLE,public.t_audit_test,CREATE TABLE t_audit_test(col text),<not logged>
2025-10-27 22:56:17.667 -03 [1936] postgres@qualitydb LOG:  AUDIT: SESSION,5,1,ROLE,ALTER ROLE,,,ALTER ROLE test_role LOGIN,<not logged>
```

### 3.4. Filtrar Apenas Linhas de Auditoria (Dica Extra)

Para isolar apenas as linhas geradas pelo `pgaudit` e tornar a leitura mais fácil, você pode usar o comando `grep` no Linux.

```bash
# Supondo que o log do dia esteja em 'postgresql-Mon.log'
grep "AUDIT" /var/lib/pgsql/17/data/log/postgresql-Mon.log > /var/lib/pgsql/17/data/log/pgaudit_lines-Mon.log
```
