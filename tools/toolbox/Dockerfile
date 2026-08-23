FROM debian:trixie-slim

# No prompts, thank you
ENV DEBIAN_FRONTEND=noninteractive

# Ansible requires python3
# ca-certificates, curl, gnupg, and lsb_release are so we can get HashiCorp's apt repo for Packer
# docker-cli is because we'll be using DooD and running commands from the toolbox against the host OS's Docker socket in the toolbox container
# openssh-client because we're going to be doing a lot of SSH work
# shellcheck because we're going to write a lot of shell scripts, and linting is nice to have
# python3-pip because python package manager, and we want ruff for linting our python files

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
        ansible-core \
        docker-cli \
        docker-compose \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        openssh-client \
        python3 \
        shellcheck \
        iputils-ping \
        python3-pip \
    && ansible-galaxy collection install -p /usr/share/ansible/collections \
        ansible.posix \
        community.crypto \
        community.postgresql \
    && rm -rf /var/lib/apt/lists/*

# Oh HashiCorp...
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg \
      | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" \
      | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    apt-get install --yes --no-install-recommends packer=1.16.0-* && \
    rm -rf /var/lib/apt/lists/*

# linting
RUN pip install --break-system-packages ruff

# Boot to a terminal if no command is given
CMD ["bash"]