source "docker" "postgres" {
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
    postgres_scripts_dir = "${var.scripts_root}/postgres"
}

build {
    name = "demo-postgres-custom"
    sources = [
        "source.docker.postgres"        # see the definition at the source block
    ]

    provisioner "shell" {
        environment_vars = [
            "DEBIAN_FRONTEND=noninteractive"
        ]

        scripts = [
            "${local.postgres_scripts_dir}/init-apt.sh",
            "${local.postgres_scripts_dir}/install-postgres-packages.sh"
        ]
    }

    // supervisor package must already be installed so /etc/supervisor exists
    provisioner "file" {
        source      = "${local.postgres_scripts_dir}/supervisord.conf"
        destination = "/etc/supervisor/supervisord.conf"
    }

    provisioner "shell" {
        environment_vars = [
            "DEBIAN_FRONTEND=noninteractive"
        ]

        scripts = [
            "${local.postgres_scripts_dir}/cleanup.sh"
        ]
    }

    post-processor "docker-tag" {
        repository = var.postgres_image_name
        tags = [var.image_tag]
    }
}