## Instalação do PostgreSQL 13 em Oracle Linux/CentOS

Este guia detalha os passos para instalar o repositório PostgreSQL, instalar o servidor PostgreSQL 13, inicializar o cluster de banco de dados e configurar o serviço para iniciar automaticamente.

### 1. Instalando o Repositório PostgreSQL

Instale o pacote RPM do repositório PostgreSQL:

```bash
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
```

### 2. Instalando o PostgreSQL 13 Server

Instale o pacote `postgresql13-server` utilizando `yum`:

```bash
yum install -y postgresql13-server
```

### 3. Inicializando o Cluster de Banco de Dados

Inicialize o cluster de banco de dados PostgreSQL 13:

```bash
/usr/pgsql-13/bin/postgresql-13-setup initdb
```

### 4. Configurando o Serviço para Iniciar no Boot

Configure o serviço `postgresql-13` para iniciar automaticamente quando o servidor for iniciado:

```bash
systemctl enable postgresql-13
systemctl start postgresql-13
```
