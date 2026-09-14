#!/usr/bin/bash

# -e => stop if any of these commands fail, do not run the remaining lines
# -u => fail on an unset variable
# -o pipefail handles any failures with | to report errors, without it you only get the final error
set -euo pipefail

# We run packer from docker-out-of-docker in toolbox. This means the docker app has no idea what
# the /work directory means. So, we had to mount the project's directory at it's own bind volume,
# and then we must point packer's temp directory at that so that docker and packer both work from
# the same place
export PACKER_TMP_DIR="${HOST_PROJECT_DIR:?HOST_PROJECT_DIR not set, see compose.yml}/.packer-tmp"
mkdir -p "$PACKER_TMP_DIR"

packer init packer/
packer build -only='debian-custom.docker.debian_trixie' packer/
packer build -only='demo-postgres-custom.docker.postgres' packer/
packer build -only='demo-nginx-custom.docker.nginx' packer/
packer build -only='demo-apache-python-custom.docker.apache-python' packer/
packer build -only='demo-ansible-bastion-custom.docker.ansible-bastion' packer/
packer build -only='demo-api-endpoint-custom.docker.java' packer/
