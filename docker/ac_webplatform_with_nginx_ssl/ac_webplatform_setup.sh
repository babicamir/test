#!/bin/bash
# Default values
DEFAULT_LINUX_DNS_HOSTNAME=ac.example-company.net
DEFAULT_AC_IMAGE_VERSION=ac910
DEFAULT_SAPSYSTEM_URI_NAME=SAPSYSTEM_URI_T01
DEFAULT_SAPSYSTEM_URI_VALUE=http://bti1121.bti.local.com:8020
DEFAULT_SSL_VALIDITY=365 # in months
KEY_NAME="private.key"
CERTIFICATE_NAME="certificate.crt"

# Intro message
echo "Welcome to Active Control Web Platform Setup."
echo "This script will install and configure docker, docker-compose, prepare docker compose YML manifest, generate Self Signed SSL certificate, and run the Active Control Web platform!"
echo ""
echo "Please enter required information below!?"

# Get input ENV variables!?
# LINUX_DNS_HOSTNAME
read -p "Please enter DNS hostname of you Linux instance (default value: $DEFAULT_LINUX_DNS_HOSTNAME): " LINUX_DNS_HOSTNAME
LINUX_DNS_HOSTNAME=${LINUX_DNS_HOSTNAME:-$DEFAULT_LINUX_DNS_HOSTNAME}

# SAPSYSTEM_URI_NAME
read -p  "Please enter full SAPSYSTEM Environment variable NAME (default value: $DEFAULT_SAPSYSTEM_URI_NAME): " SAPSYSTEM_URI_NAME
SAPSYSTEM_URI_NAME=${SAPSYSTEM_URI_NAME:-$DEFAULT_SAPSYSTEM_URI_NAME}

# SAPSYSTEM_URI_VALUE
read -p  "Please enter full SAPSYSTEM Environment variable VALUE (default value: $DEFAULT_SAPSYSTEM_URI_VALUE): " SAPSYSTEM_URI_VALUE
SAPSYSTEM_URI_VALUE=${SAPSYSTEM_URI_VALUE:-$DEFAULT_SAPSYSTEM_URI_VALUE}

# AC_IMAGE_VERSION
read -p "Please enter Active Control Container Image version (default value: $DEFAULT_AC_IMAGE_VERSION): " AC_IMAGE_VERSION
AC_IMAGE_VERSION=${AC_IMAGE_VERSION:-$DEFAULT_AC_IMAGE_VERSION}

# SSL_VALIDITY
read -p "How long do you want your SSL certificate to last? (default value: $DEFAULT_SSL_VALIDITY days): " SSL_VALIDITY
SSL_VALIDITY=${SSL_VALIDITY:-$DEFAULT_SSL_VALIDITY}

# Print all ENV variables
echo ""
echo "The following values are entered/selected:"
echo "DNS hostname of you Linux instance:           $LINUX_DNS_HOSTNAME"
echo "SAPSYSTEM Environment variable NAME:          $SAPSYSTEM_URI_NAME"
echo "SAPSYSTEM Environment variable VALUE:         $SAPSYSTEM_URI_VALUE"
echo "Active Control Container Image version:       $AC_IMAGE_VERSION"
echo ""
read -p "Prease ENTER to continue setup!?" WAIT


# Downloading required templates!"
echo "Downloading required templates!"
sleep 2s
wget https://raw.githubusercontent.com/babicamir/test/main/docker/ac_webplatform_with_nginx_ssl/ac_webplatform_template.yml -O ac_webplatform.yml
wget https://raw.githubusercontent.com/babicamir/test/main/docker/ac_webplatform_with_nginx_ssl/nginx.conf

# Updating templates with above ENV variables
echo "Updating templates with above ENV variables!"
sleep 2s
# Preparing docker-compose yml manifest
sed -i \
"s~<AC_IMAGE_VERSION>~$AC_IMAGE_VERSION~g; \
s~<SAPSYSTEM_URI_NAME>~$SAPSYSTEM_URI_NAME~g; \
s~<SAPSYSTEM_URI_VALUE>~$SAPSYSTEM_URI_VALUE~g;" \
ac_webplatform.yml
 
# Preparing nginx conf
sed -i \
"s~<LINUX_DNS_HOSTNAME>~$LINUX_DNS_HOSTNAME~g;" \
nginx.conf
 

# Installing Docker and Docker Compose
echo "Starting installation of Docker engine!"
sleep 2s
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
 
echo "Starting installation of Docker Compose plugin!"
wget https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64 -O /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#groupadd docker
all_users=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)
usermod -aG docker $all_users
newgrp docker && exit
systemctl enable docker.service
systemctl enable containerd.service
systemctl start docker.service

echo ""
echo "Docker and Docker Compose successfully installed"
docker -v
docker-compose -v
sleep 2s
echo ""

# SSL
# Generation of private key and SSL certificate!
echo "Starting generation of private key and SSL certificate!"
sleep 2s
mkdir ssl

# Generate a Private Key
openssl genrsa -out "./ssl/$KEY_NAME" 2048
 
# Generate a CSR
openssl req -new -key "./ssl/$KEY_NAME" -out "./ssl/CertificateSigningRequest.csr" -subj "/CN=$LINUX_DNS_HOSTNAME"

# Generate and sing a self-signed certificate
openssl x509 -req -in "./ssl/CertificateSigningRequest.csr" -signkey "./ssl/$KEY_NAME" -days $SSL_VALIDITY -out "./ssl/$CERTIFICATE_NAME"
 
echo ""
echo "Private key and SSL certificate generated:"
echo "Certificate (*.key): ./ssl/$CERTIFICATE_NAME"
echo "Private Key (*.crt): ./ssl/$KEY_NAME"

# Celanup
rm ./get-docker.sh



# End messages!?
echo ""
echo ""
echo ""
echo "Active Control Web Platform Setup completed!"
echo "Thank you for your patience!"
echo ""
echo ""
echo "To Active Control Web Platform container, please run: docker-compose up -f ac_webplatform.yml -d"
echo ""
read -p "Prease ENTER to finish setup!?" WAIT

