## Instalação e Configuração do PostgreSQL no Ubuntu/Debian

Este guia detalha os passos para atualizar o sistema, instalar o servidor PostgreSQL, iniciar o serviço, criar usuários e bancos de dados, e verificar o status do serviço.

### 1. Atualizando o Sistema Operacional

Atualize os pacotes e listas de pacotes do sistema:

```bash
sudo apt-get update && sudo apt-get upgrade
```

### 2. Instalando o PostgreSQL

Instale o PostgreSQL e os pacotes contrib (ferramentas adicionais):

```bash
sudo apt install postgresql postgresql-contrib
```

### 3. Iniciando o Serviço PostgreSQL

Inicie o serviço PostgreSQL:

```bash
sudo systemctl start postgresql.service
```

### 4. Acessando o Usuário PostgreSQL

Acesse o usuário `postgres` no sistema operacional:

```bash
sudo -i -u postgres
```

### 5. Acessando o Prompt do PostgreSQL (psql)

Acesse o prompt do PostgreSQL (psql):

```bash
psql
```

### 6. Saindo do Prompt psql e do Usuário PostgreSQL

Saia do prompt psql e retorne ao usuário anterior:

```sql
\q
exit
```

### 7. Acessando Diretamente o psql com o Usuário PostgreSQL

Acesse diretamente o prompt psql com o usuário `postgres`:

```bash
sudo -u postgres psql
```

### 8. Saindo do psql

Saia do prompt psql:

```sql
\q
```

### 9. Criando um Usuário no PostgreSQL

Crie um novo usuário no banco de dados (é recomendado que o usuário também exista no sistema operacional):

```bash
sudo -u postgres createuser --interactive
```

* O comando ira lhe pedir para inserir o nome do usuário, e se você quer ou não criar esse usuário como super usuário.

### 10. Criando um Banco de Dados

Crie um novo banco de dados:

```bash
createdb databasename
```

ou

```bash
sudo -u postgres createdb databasename
```

### 11. Adicionando um Usuário ao Sistema (Opcional)

Adicione um novo usuário ao sistema operacional (caso necessário):

```bash
sudo adduser sammy
```

### 12. Métodos para Acessar o psql com um Usuário Específico

Existem diversas maneiras de acessar o psql com um usuário específico:

```bash
sudo -i -u sammy
psql

sudo -u sammy psql

psql -d database_name
```

### 13. Verificando Informações de Conexão

Dentro do psql, verifique as informações de conexão:

```sql
\conninfo
```

### 14. Verificando o Status do Serviço PostgreSQL

Verifique o status do serviço PostgreSQL:

```bash
sudo systemctl status postgresql.service
```
