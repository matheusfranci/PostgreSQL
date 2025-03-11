## Instalação e Execução do Postgres Checkup com Relatórios PDF

Este guia detalha os passos para instalar as dependências necessárias, clonar o repositório `postgres-checkup`, compilar a ferramenta e executar a análise de um banco de dados PostgreSQL, gerando relatórios em PDF.

### 1. Instalação de Programas Necessários

Instale as dependências principais para a execução do checkup:

```bash
sudo yum install -y git coreutils jq golang
```

### 2. Instalação do Pandoc (Opcional)

Instale o `pandoc`, necessário para a geração de relatórios em PDF:

```bash
sudo yum install -y pandoc
```

### 3. Download do wkhtmltopdf

Baixe o pacote `wkhtmltopdf` diretamente da web:

```bash
wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
```

### 4. Descompactação do wkhtmltopdf

Descompacte o pacote baixado:

```bash
tar xvf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
```

### 5. Movendo Binários do wkhtmltopdf

Mova os binários do `wkhtmltopdf` para um diretório personalizado:

```bash
sudo mv wkhtmltox/bin/wkhtmlto* /usr/local/bin
```

### 6. Instalação de Dependências Adicionais

Instale dependências adicionais para o `wkhtmltopdf`:

```bash
sudo yum install -y libpng libjpeg openssl icu libX11 libXext libXrender xorg-x11-fonts-Type1 xorg-x11-fonts-75dpi
```

### 7. Clonagem do Repositório Postgres Checkup

Clone o repositório `postgres-checkup` do GitHub:

```bash
git clone https://gitlab.com/postgres-ai/postgres-checkup.git
```

### 8. Navegação e Compilação do Postgres Checkup

Navegue até o diretório `pghrep` e compile o projeto:

```bash
cd /var/lib/postgresql/orion/assessment/postgres-checkup/
cd ./pghrep
make main
```

### 9. Retorno ao Diretório Principal do Checkup

Retorne ao diretório principal do `postgres-checkup`:

```bash
cd /var/lib/postgresql/orion/assessment/postgres-checkup
```

### 10. Execução do Postgres Checkup

Execute o `postgres-checkup` com os parâmetros desejados:

```bash
./checkup -h BRSRV080O -p 5432 --username postgres --dbname postgres --project qualquer_nome_sera_criado_na_hora -e 1 --pdf
```

Ou, utilizando o caminho completo para o executável:

```bash
./var/lib/postgresql/orion/assessment/postgres-checkup/checkup -h BRSRV080O -p 5432 --username postgres --dbname postgres --project qualquer_nome_sera_criado_na_hora -e 1 --pdf
```

**Explicação dos parâmetros:**

* `./checkup`: Chama o executável `checkup`.
* `-h BRSRV080O -p 5432 --username postgres --dbname postgres`: Define o host, porta, usuário e banco de dados para conexão.
* `--project qualquer_nome_sera_criado_na_hora`: Define o nome do projeto (diretório dentro de `artifacts` onde o relatório será salvo).
* `-e 1`: Executa todos os testes.
* `--pdf`: Gera um relatório em PDF.
