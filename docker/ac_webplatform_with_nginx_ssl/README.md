# Basis Technologies ActiveControl Web Platform Docker Compose

## Overview
This Docker Compose file is designed to deploy and run the Active Control Web Platform container using a specified container image version. The platform is configured to connect to an SAP system using the provided SAPSYSTEM_URI, and logging settings can be customized through environment variables.

This version of docker-compose YML manifest will run Active Control Web Platform container and expose it on defined port (default version is 9200).

## Prerequisites
- Docker and Docker-compose installed on the host machine

## Create YML file
Create new docker-compose YML file and name it as "ac_webplatform.yml"

## Update environment variables
Please check documentation

## Prepare SSL
An SSL private key and certificate should be prepared to enable HTTPS communications between users and Linux instance. You can use bought SSL certificates or signed key and certificate. 
SSL certificate should match endpoint domain that you want to use for your Linux instance (e.g. bti1121.bti.local.com).

SSL private key and certificate should be saved within SSL folder and named like:
- certificate.crt
- private.key

## Update nginx configuration
Open existing file "nginx.conf" and update:
- server_name 

## Run docker compose file
Run the following command in the directory containing this Docker Compose file:
```
   docker compose -f ac_webplatform.yml up -d
```

6. Open browser and access to Active Control Web Platform via https://<DNS-OR-IP-OF-LINUX-INSTANCE>