#!/bin/bash
# Default values


echo "0"
getent group docker
usermod -aG docker $USER
echo "1"
getent group docker
