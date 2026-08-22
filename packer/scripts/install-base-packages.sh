#!/usr/bin/bash

apt-get update
apt-get install -y --no-install-recommends curl ca-certificates sudo python3
apt-get clean
rm -rf /var/lib/apt/lists/*