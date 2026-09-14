#!/usr/bin/bash

mv /tmp/master_key /home/deploy/.ssh/id_ed25519
chown deploy:deploy /home/deploy/.ssh/id_ed25519
chmod 600 /home/deploy/.ssh/id_ed25519