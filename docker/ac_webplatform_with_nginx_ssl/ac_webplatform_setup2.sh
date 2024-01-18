#!/bin/bash
# Default values



usermod -aG docker $USER
getent group docker
