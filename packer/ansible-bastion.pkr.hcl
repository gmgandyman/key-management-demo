source "docker" "ansible-bastion" {
    image = "${var.base_image_name}:${var.image_tag}"
    commit = true
    pull = false    # this comes from our local instance

    # docker inspect --format '{{.Config.Cmd}}' debian:trixie-slim will show [bash] as the final CMD
    # that will get appended to our entrypoint, so prevent it by setting our own CMD
    # -D tells sshd to not daemonize, we need it to stay in foreground, -e prints errors to stderr
    # Also, use JSON, no shell, because we want to catch docker end signals
    changes = [
        "ENTRYPOINT ${jsonencode(["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"])}",
        "CMD []"
    ]
}

locals {
    ansible-bastion_scripts_dir = "${var.scripts_root}/ansible-bastion"
}

build {
    name = "demo-ansible-bastion-custom"
    sources = [
        "source.docker.ansible-bastion"        # see the definition at the source block
    ]

    // Setup a copy in /tmp, because scripts/ansible-bastion/move-master-key.sh will need it
    provisioner "file" {
        source      = "keys/master_key"
        destination = "/tmp/master_key"
    }

    provisioner "shell" {
        environment_vars = [
            "DEBIAN_FRONTEND=noninteractive"
        ]

        scripts = [
            "${local.ansible-bastion_scripts_dir}/init-apt.sh",
            "${local.ansible-bastion_scripts_dir}/install-ansible-bastion-packages.sh"
        ]
    }

    // supervisor package must already be installed so /etc/supervisor exists
    provisioner "file" {
        source      = "${local.ansible-bastion_scripts_dir}/supervisord.conf"
        destination = "/etc/supervisor/supervisord.conf"
    }

    provisioner "shell" {
        environment_vars = [
                    "DEBIAN_FRONTEND=noninteractive"
        ]

        scripts = [
            "${local.ansible-bastion_scripts_dir}/cleanup.sh"
        ]
    }

    post-processor "docker-tag" {
        repository = var.bastion_image_name
        tags = [var.image_tag]
    }
}
