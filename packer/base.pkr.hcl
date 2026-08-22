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
            "packer/scripts/install-base-packages.sh",
            "packer/scripts/install-sshd.sh",
            "packer/scripts/setup-nopasswd-sudo.sh"
        ]
    }

    // Upload the master key's public key to the server, just use tmp for now
    provisioner "file" {
        source = "keys/master_key.pub"
        destination = "/tmp/master_key.pub"
    }

    provisioner "shell" {
        scripts = [
            "packer/scripts/add-deploy-user.sh",
            "packer/scripts/setup-ssh-directory.sh"
        ]
    }

    post-processor "docker-tag" {
        repository = "simple-server"
        tags = ["demo-trixie-slim"]
    }
}