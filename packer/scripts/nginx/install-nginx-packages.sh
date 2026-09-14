#!/usr/bin/bash

# Cyptography is so we can generate a self-signed cert with ansible
# supervisor is so we can boot multiple processes as our endpoint for the container
apt-get install -y --no-install-recommends nginx supervisor python3-cryptography
