Install required programs
Ubuntu/Debian:

sudo apt-get update -y
sudo apt-get install -y git postgresql coreutils jq golang  #Esse instala o postgresql 15 e é necessário

# Optional (to generate PDF/HTML reports) é bom ter e deve ser criado em um repositório segue exemplo:
# /var/lib/postgresql/orion/assessment/  Não se esqueça de permissionar ao usuário postgres caso o diretório seja criado com o root
# chown postgres:postgres /var/lib/postgresql/orion/ -R
sudo apt-get install -y pandoc
wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
tar xvf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
sudo mv wkhtmltox/bin/wkhtmlto* /usr/local/bin
sudo apt-get install -y openssl libssl-dev libxrender-dev libx11-dev libxext-dev libfontconfig1-dev libfreetype6-dev fontconfig


CentOS/RHEL:
sudo yum install -y git postgresql coreutils jq golang
# Optional (to generate PDF/HTML reports) é bom ter e deve ser criado em um repositório por exemplo pg_dir/orion/assessment
sudo yum install -y pandoc
wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
tar xvf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
sudo mv wkhtmltox/bin/wkhtmlto* /usr/local/bin
sudo yum install -y libpng libjpeg openssl icu libX11 libXext libXrender xorg-x11-fonts-Type1 xorg-x11-fonts-75dpi

# Comando para copiar o repositório para a vm
git clone https://gitlab.com/postgres-ai/postgres-checkup.git


# crie um diretório no / para administrar isso
cd /var/lib/postgresql/orion/assessment/postgres-checkup/
cd ./pghrep
make main
cd ..

#Após pode-se criar diretórios com nome dos projetos para a variável --project, segue exemplo:
#/var/lib/postgresql/orion/assessment/postgres-checkup/artifacts
#Precisa ser dentro do diretório artifacts
#mkdir database1
#mkdir database2

./checkup -h nomedohost -p 5432 --username postgres --dbname database1 --project database1 -e 1 --pdf 
#--pdf é opcional mas ele gera um relatório em pdf que é melhor para analisar.
