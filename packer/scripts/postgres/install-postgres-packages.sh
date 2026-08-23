#!/usr/bin/bash

# postgresql is obvious, supervisord lets us run multiple services in our container as the entrypoint
apt-get install -y --no-install-recommends postgresql-17 supervisor
