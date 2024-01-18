#!/bin/bash
# Default values


echo "0"
getent group docker
sudo usermod -aG docker $USER
newgrp docker
echo "1"
getent group docker
