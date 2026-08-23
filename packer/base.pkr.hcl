# We need the docker plugin, note that is requires the CLI and socker up at runtime
# It also needs your docker executables on the PATH env variable
packer {
    required_plugins {
        docker = {
            version = ">= 1.0.8"
            source = "github.com/hashicorp/docker"
        }
    }
}

source "docker" "debian_trixie" {
    image = "debian:trixie-slim"
    commit = true

    # docker inspect --format '{{.Config.Cmd}}' debian:trixie-slim will show [bash] as the final CMD
    # that will get appended to our entrypoint, so prevent it by setting our own CMD

    # -D tells sshd to not daemonize, we need it to stay in foreground, -e prints erros to stderr
    # Also, use JSON, no shell, because we want to catch docker end signals
    changes = [
        "ENTRYPOINT [\"/usr/sbin/sshd\", \"-D\", \"-e\"]",
        "CMD []"
    ]
}

locals {
    base_scripts_dir = "${var.scripts_root}/base"
}

build {
    name = "debian-custom"
    sources = [
        "source.docker.debian_trixie"
    ]

    provisioner "shell" {
        environment_vars = [
            "DEBIAN_FRONTEND=noninteractive"
        ]

        scripts = [
            "${local.base_scripts_dir}/init-apt.sh",
            "${local.base_scripts_dir}/install-base-packages.sh",
            "${local.base_scripts_dir}/install-sshd.sh",
            "${local.base_scripts_dir}/setup-nopasswd-sudo.sh"
        ]
    }

    // Upload the master key's public key to the server, just use tmp for now
    provisioner "file" {
        source = "keys/master_key.pub"
        destination = "/tmp/master_key.pub"
    }

    provisioner "shell" {
        scripts = [
            "${local.base_scripts_dir}/add-deploy-user.sh",
            "${local.base_scripts_dir}/setup-ssh-directory.sh",
            "${local.base_scripts_dir}/cleanup.sh"
        ]
    }

    post-processor "docker-tag" {
        repository = var.base_image_name
        tags = [var.image_tag]
    }
}