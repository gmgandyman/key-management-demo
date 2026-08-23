#!/usr/bin/bash

# -e => stop if any of these commands fail, do not run the remaining lines
# -u => fail on an unset variable
# -o pipefail handles any failures with | to report errors, without it you only get the final error
set -euo pipefail
packer init packer/
packer build -only='debian-custom.docker.debian_trixie' packer/
packer build -only='demo-postgres-custom.docker.postgres' packer/
