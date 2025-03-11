## Instalação e Configuração do PostgreSQL no CentOS/RHEL

Este guia detalha os passos para verificar atualizações, instalar o servidor PostgreSQL, inicializar o banco de dados, iniciar o serviço e configurá-lo para iniciar automaticamente no boot do sistema.

### 1. Verificando Atualizações de Pacotes

Primeiro, verifique se há atualizações disponíveis para os pacotes do sistema:

```bash
yum check-update
```

### 2. Atualizando Pacotes

Atualize todos os pacotes do sistema para as versões mais recentes:

```bash
yum update
```

### 3. Verificando Informações do Pacote PostgreSQL

Verifique as informações do pacote `postgresql-server` para confirmar a versão e dependências:

```bash
yum info postgresql-server
```

### 4. Instalando o Pacote PostgreSQL Server

Instale o pacote `postgresql-server` utilizando `yum`:

```bash
yum -y install postgresql-server
```

### 5. Inicializando o Banco de Dados PostgreSQL

Inicialize o banco de dados PostgreSQL utilizando o comando `initdb`:

```bash
service postgresql initdb
```

### 6. Iniciando o Cluster PostgreSQL

Inicie o serviço PostgreSQL (cluster):

```bash
service postgresql start
```

### 7. Configurando o PostgreSQL para Iniciar no Boot

Configure o serviço PostgreSQL para iniciar automaticamente quando o servidor for iniciado:

```bash
chkconfig postgresql on
```
