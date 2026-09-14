source "docker" "apache-python" {
    image = "${var.base_image_name}:${var.image_tag}"
    commit = true
    pull = false    # this comes from our local instance


    # Supervisor lets us run multiple things as our entrypoint
    # docker inspect --format '{{.Config.Cmd}}' debian:trixie-slim will show [bash] as the final CMD
    # that will get appended to our entrypoint, so prevent it by setting our own CMD
    # Also, use JSON, no shell, because we want to catch docker end signals
    changes = [
        "ENTRYPOINT ${jsonencode(["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"])}",
        "CMD []"
    ]
}

locals {
    apache-python_scripts_dir = "${var.scripts_root}/apache-python"
}

build {
    name = "demo-apache-python-custom"
    sources = [
        "source.docker.apache-python"        # see the definition at the source block
    ]

    provisioner "shell" {
        environment_vars = [
            "DEBIAN_FRONTEND=noninteractive"
        ]

        scripts = [
            "${local.apache-python_scripts_dir}/init-apt.sh",
            "${local.apache-python_scripts_dir}/install-apache-python-packages.sh"
        ]
    }

    // supervisor package must already be installed so /etc/supervisor exists
    provisioner "file" {
        source      = "${local.apache-python_scripts_dir}/supervisord.conf"
        destination = "/etc/supervisor/supervisord.conf"
    }

    provisioner "shell" {
        environment_vars = [
            "DEBIAN_FRONTEND=noninteractive"
        ]

        scripts = [
            "${local.apache-python_scripts_dir}/cleanup.sh"
        ]
    }

    post-processor "docker-tag" {
        repository = var.apache_image_name
        tags = [var.image_tag]
    }
}