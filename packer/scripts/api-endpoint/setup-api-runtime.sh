#!/usr/bin/bash

# Runs at Packer build time on the ansible-bastion image.
# Places the break-glass master key and the API runtime scaffolding.

set -euo pipefail

# --- SSH client defaults for deploy --------------------------------------------
# Keeps a dead target from hanging an API request, and forces one identity so a
# future loaded agent can't trip MaxAuthTries (plan.md traps #11, #12, #14).
cat > /home/deploy/.ssh/config <<'EOF'
Host *
    IdentitiesOnly yes
    IdentityFile ~/.ssh/id_ed25519
    BatchMode yes
    ConnectTimeout 5
    StrictHostKeyChecking accept-new
EOF
chown deploy:deploy /home/deploy/.ssh/config
chmod 600 /home/deploy/.ssh/config

# --- API runtime dir ----------------------------------------------------------
# Dev bind-mounts the jar over compose; kept for a baked image where API_JAR_DIR=/opt/api.
mkdir -p /opt/api
chown deploy:deploy /opt/api
