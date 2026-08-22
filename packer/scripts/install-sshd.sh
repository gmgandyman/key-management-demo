#!/usr/bin/bash

apt-get update
apt-get install -y --no-install-recommends openssh-server
apt-get clean
rm -rf /var/lib/apt/lists/*