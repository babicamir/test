#!/bin/bash
# Default values
DEFAULT_LINUX_DNS_HOSTNAME=ac.example-company.net
DEFAULT_AC_IMAGE_VERSION=ac910
DEFAULT_SAPSYSTEM_SECURED_URI=yes
DEFAULT_SAPSYSTEM_URI_NAME_v1=SAPSYSTEM_URI_T01
DEFAULT_SAPSYSTEM_URI_NAME_v2=SAPSYSTEM_SECURED_URI_T01
DEFAULT_SAPSYSTEM_URI_VALUE_v1=http://bti1121.bti.local.com:8020
DEFAULT_SAPSYSTEM_URI_VALUE_v2=https://bti1121.bti.local.com:8020

DEFAULT_SSL_VALIDITY=365 # in months
KEY_NAME="private.key"
CERTIFICATE_NAME="certificate.crt"





# Intro message
echo "Welcome to Active Control Web Platform Setup."
echo "This script will install and configure docker, docker-compose, prepare docker compose YML manifest, generate Self Signed SSL certificate, and run the Active Control Web platform!"
echo "This script is supported for the following Linux Distributions: Amazon Linux, Amazon Linux 2, Ubuntu 22, Ubuntu 20, Ubuntu 18, Suse 15, Suse 12, RedHat 9 and RedHat 8"
echo ""
echo "Please enter required information below!?"





 


# Get input ENV variables!?
# Usage of SAPSYSTEM_SECURED_URI
read -p "Do you want to configure secure HTTPS connection between ActiveControl Web Platform container and SAP ActiveControl Domain Controller SICF [yes or no] (default value: $DEFAULT_SAPSYSTEM_SECURED_URI): " SAPSYSTEM_SECURED_URI 
SAPSYSTEM_SECURED_URI=${SAPSYSTEM_SECURED_URI:-$DEFAULT_SAPSYSTEM_SECURED_URI}

# SAPSYSTEM_URI_NAME
if [ "$APSYSTEM_SECURED_URI" = "no" ]; then
    # SAPSYSTEM_URI_NAME
    read -p  "Please enter full SAPSYSTEM Environment variable VALUE (default value: $DEFAULT_SAPSYSTEM_URI_NAME_v1): " SAPSYSTEM_URI_NAME
    SAPSYSTEM_URI_NAME=${SAPSYSTEM_URI_NAME:-$DEFAULT_SAPSYSTEM_URI_NAME_v1}
else
    # SAPSYSTEM_URI_NAME
    read -p  "Please enter full SAPSYSTEM Environment variable VALUE (default value: $DEFAULT_SAPSYSTEM_URI_NAME_v2): " SAPSYSTEM_URI_NAME
    SAPSYSTEM_URI_NAME=${SAPSYSTEM_URI_NAME:-$DEFAULT_SAPSYSTEM_URI_NAME_v2}
fi

# SAPSYSTEM_URI_VALUE
if [ "$APSYSTEM_SECURED_URI" = "no" ]; then
    # SAPSYSTEM_URI_VALUE
    read -p  "Please enter full SAPSYSTEM Environment variable VALUE (default value: $DEFAULT_SAPSYSTEM_URI_VALUE_v1): " SAPSYSTEM_URI_VALUE
    SAPSYSTEM_URI_VALUE=${SAPSYSTEM_URI_VALUE:-$DEFAULT_SAPSYSTEM_URI_VALUE_v1}
else
    # SAPSYSTEM_URI_NAME
    read -p  "Please enter full SAPSYSTEM Environment variable VALUE (default value: $DEFAULT_SAPSYSTEM_URI_VALUE_v2): " SAPSYSTEM_URI_VALUE
    SAPSYSTEM_URI_VALUE=${SAPSYSTEM_URI_VALUE:-$DEFAULT_SAPSYSTEM_URI_VALUE_v2}
fi

# AC_IMAGE_VERSION
read -p "Please enter Active Control Container Image version (default value: $DEFAULT_AC_IMAGE_VERSION): " AC_IMAGE_VERSION
AC_IMAGE_VERSION=${AC_IMAGE_VERSION:-$DEFAULT_AC_IMAGE_VERSION}

# LINUX_DNS_HOSTNAME
read -p "Please enter DNS hostname of you Linux instance (default value: $DEFAULT_LINUX_DNS_HOSTNAME): " LINUX_DNS_HOSTNAME
LINUX_DNS_HOSTNAME=${LINUX_DNS_HOSTNAME:-$DEFAULT_LINUX_DNS_HOSTNAME}


# SSL_VALIDITY
read -p "How long do you want your SSL certificate to last? (default value: $DEFAULT_SSL_VALIDITY days): " SSL_VALIDITY
SSL_VALIDITY=${SSL_VALIDITY:-$DEFAULT_SSL_VALIDITY}





# Print all ENV variables
echo ""
echo "The following values are entered/selected:"
echo "Usage of SAPSYSTEM_SECURED_URI:               $SAPSYSTEM_SECURED_URI"
echo "DNS hostname of you Linux instance:           $LINUX_DNS_HOSTNAME"
echo "SAPSYSTEM Environment variable NAME:          $SAPSYSTEM_URI_NAME"
echo "SAPSYSTEM Environment variable VALUE:         $SAPSYSTEM_URI_VALUE"
echo "Active Control Container Image version:       $AC_IMAGE_VERSION"
echo ""
read -p "Prease ENTER to continue setup!?" WAIT


# Downloading required templates!"
echo "Downloading required templates!"
sleep 2s
curl https://raw.githubusercontent.com/babicamir/test/main/docker/ac_webplatform_with_nginx_ssl/ac_webplatform_template.yml -o ac_webplatform.yml
curl https://raw.githubusercontent.com/babicamir/test/main/docker/ac_webplatform_with_nginx_ssl/nginx.conf -o nginx.conf



# SAPSYSTEM_URI_NAME
if [ "$APSYSTEM_SECURED_URI" = "no" ]; then
    curl https://raw.githubusercontent.com/babicamir/test/main/docker/ac_webplatform_with_nginx_ssl/ac_webplatform_template_1.yml -o ac_webplatform.yml
    curl https://raw.githubusercontent.com/babicamir/test/main/docker/ac_webplatform_with_nginx_ssl/nginx.conf -o nginx.conf
else
    curl https://raw.githubusercontent.com/babicamir/test/main/docker/ac_webplatform_with_nginx_ssl/ac_webplatform_template_2.yml -o ac_webplatform.yml
    curl https://raw.githubusercontent.com/babicamir/test/main/docker/ac_webplatform_with_nginx_ssl/nginx.conf -o nginx.conf
    touch ./ssl/RootCAcertificate.crt
fi


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
 

echo "Starting installation of Docker engine!"
sleep 2s
#Get Linux distribution ID
if [ -e /etc/os-release ]; then
    # Extract the ID variable from /etc/os-release using awk and cut
    distribution_id=$(awk -F= '/^ID=/{gsub(/"/, "", $2); print $2}' /etc/os-release)    
    # Display the distribution ID
    echo "Distribution ID: $distribution_id"
else
    echo "Error: /etc/os-release file not found."
fi

# Install Docker
if [ "$distribution_id" = "amzn" ]; then
    echo "This is Amazon Linux distribution" 
    sudo yum update -y
    sudo yum install docker -y
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
    sudo systemctl start docker.service
    sudo usermod -aG docker $USER

    # Installing docker compose
    sudo echo "Starting installation of Docker Compose plugin!"
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

elif [ "$distribution_id" = "ubuntu" ]; then
    echo "This is UBUNTU Linux distribution" 
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo rm ./get-docker.sh

    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
    sudo systemctl start docker.service
    sudo usermod -aG docker $USER

    # Installing docker compose
    sudo echo "Starting installation of Docker Compose plugin!"
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    

elif [ "$distribution_id" = "rhel" ]; then
    echo "This is RedHat Linux distribution" 
    sudo dnf update -y
    sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io

    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
    sudo systemctl start docker.service
    sudo usermod -aG docker $USER

    # Installing docker compose
    sudo echo "Starting installation of Docker Compose plugin!"
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose 

elif [ "$distribution_id" = "sles" ]; then
    echo "This is SUSE Linux distribution" 
    sudo zypper addrepo https://download.docker.com/linux/sles/docker-ce.repo
    sudo zypper install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
    sudo systemctl start docker.service
    sudo usermod -aG docker $USER

    # Installing docker compose
    sudo echo "Starting installation of Docker Compose plugin!"
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose 

else
    echo "This Linux Distribution is not supported!?"
fi
 

echo "##################################################################"
echo "##################################################################"
echo "Docker and Docker Compose successfully installed"
echo "##################################################################"
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

newgrp docker
exit