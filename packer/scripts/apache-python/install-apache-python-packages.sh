#!/usr/bin/bash

# postgresql is obvious, supervisord lets us run multiple services in our container as the entrypoint
apt-get install -y --no-install-recommends apache2 \
  libapache2-mod-wsgi-py3 \
  python3 \
  python3-venv \
  python3-pip \
  supervisor
