## Instalação e Execução do Postgres Checkup para Avaliação de PostgreSQL

Este guia detalha os passos para instalar as dependências necessárias, clonar o repositório `postgres-checkup`, compilar a ferramenta e executar a análise de um banco de dados PostgreSQL, incluindo a geração de relatórios em PDF.

### 1. Instalação das Dependências

Dependendo do sistema operacional (Ubuntu/Debian ou CentOS/RHEL), execute os seguintes comandos:

**Ubuntu/Debian:**

```bash
sudo apt-get update -y
sudo apt-get install -y git postgresql coreutils jq golang  # Instala o PostgreSQL 15 (necessário para alguns testes)
sudo apt-get install -y git coreutils jq golang  # Instala as dependências, exceto PostgreSQL
```

**Instalação opcional para geração de relatórios PDF/HTML:**

```bash
sudo apt-get install -y pandoc
wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
tar xvf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
sudo mv wkhtmltox/bin/wkhtmlto* /usr/local/bin
sudo apt-get install -y openssl libssl-dev libxrender-dev libx11-dev libxext-dev libfontconfig1-dev libfreetype6-dev fontconfig
```

**CentOS/RHEL:**

```bash
sudo yum install -y git postgresql coreutils jq golang
```

**Instalação opcional para geração de relatórios PDF/HTML:**

```bash
sudo yum install -y pandoc
wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
tar xvf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
sudo mv wkhtmltox/bin/wkhtmlto* /usr/local/bin
sudo yum install -y libpng libjpeg openssl icu libX11 libXext libXrender xorg-x11-fonts-Type1 xorg-x11-fonts-75dpi
```

### 2. Clonando o Repositório Postgres Checkup

Clone o repositório `postgres-checkup` para a sua máquina virtual:

```bash
git clone https://gitlab.com/postgres-ai/postgres-checkup.git
```

### 3. Compilando o Postgres Checkup

Navegue até o diretório do repositório e compile a ferramenta:

```bash
cd /var/lib/postgresql/orion/assessment/postgres-checkup/  # Ou qualquer diretório que desejar usar
cd ./pghrep
make main
cd ..
```

### 4. Executando o Postgres Checkup

Execute a ferramenta `checkup` para analisar o banco de dados. Crie diretórios dentro do diretório `artifacts` para cada projeto. Exemplo:

```bash
mkdir artifacts/database1
mkdir artifacts/database2
```

Execute o comando `checkup`:

```bash
./checkup -h nomedohost -p 5432 --username postgres --dbname database1 --project database1 -e 1 --pdf
```

* `-h nomedohost`: Endereço do host do PostgreSQL.
* `-p 5432`: Porta do PostgreSQL.
* `--username postgres`: Nome do usuário para conexão.
* `--dbname database1`: Nome do banco de dados a ser analisado.
* `--project database1`: Nome do projeto (usado para gerar o relatório em diretório especifico).
* `-e 1`: Utiliza todos os testes.
* `--pdf`: Gera um relatório em PDF.

### 5. Desinstalando o PostgreSQL 15 (Opcional)

Caso o PostgreSQL 15 tenha sido instalado apenas para a análise e não seja mais necessário, desinstale-o:

```bash
apt list --installed | grep postgresql
apt purge postgresql-15
```
