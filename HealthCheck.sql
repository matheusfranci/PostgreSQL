1. Install required programs
Ubuntu/Debian:

sudo apt-get update -y
sudo apt-get install -y git postgresql coreutils jq golang

# Optional (to generate PDF/HTML reports)
sudo apt-get install -y pandoc
wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
tar xvf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
sudo mv wkhtmltox/bin/wkhtmlto* /usr/local/bin
sudo apt-get install -y openssl libssl-dev libxrender-dev libx11-dev libxext-dev libfontconfig1-dev libfreetype6-dev fontconfig


CentOS/RHEL:

sudo yum install -y git postgresql coreutils jq golang

# Optional (to generate PDF/HTML reports)
sudo yum install -y pandoc
wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
tar xvf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
sudo mv wkhtmltox/bin/wkhtmlto* /usr/local/bin
sudo yum install -y libpng libjpeg openssl icu libX11 libXext libXrender xorg-x11-fonts-Type1 xorg-x11-fonts-75dpi

-- comando
git clone https://gitlab.com/postgres-ai/postgres-checkup.git

-- crie um diretório no / para administrar isso
cd postgres-checkup
cd ./pghrep
make main
cd ..

./checkup -h db1.vpn.local -p 5432 --username postgres --dbname postgres --project prod1 -e 1
