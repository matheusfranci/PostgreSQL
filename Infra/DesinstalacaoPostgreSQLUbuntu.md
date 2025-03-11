## Desinstalando o PostgreSQL no Ubuntu/Debian

Este guia detalha os passos para remover o PostgreSQL e seus pacotes relacionados utilizando `apt`.

### 1. Removendo o Pacote Principal do PostgreSQL

Remova o pacote principal do PostgreSQL:

```bash
sudo apt-get --purge remove postgresql
```

### 2. Removendo Todos os Pacotes Relacionados ao PostgreSQL

Remova todos os pacotes que começam com `postgresql`:

```bash
sudo apt-get purge postgresql*
```

### 3. Removendo Pacotes Específicos do PostgreSQL

Remova pacotes específicos do PostgreSQL, incluindo a documentação e pacotes comuns:

```bash
sudo apt-get --purge remove postgresql postgresql-doc postgresql-common
```

### 4. Verificando Clusters Instalados

Verifique os clusters PostgreSQL instalados no servidor:

```bash
apt list --installed | grep postgresql
```

### 5. Removendo uma Instalação Específica

Remova uma instalação específica do PostgreSQL, informando a versão:

```bash
apt purge postgresql-15  # Substitua "15" pela versão desejada
```
