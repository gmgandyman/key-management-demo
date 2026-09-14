source "docker" "nginx" {
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
    nginx_scripts_dir = "${var.scripts_root}/nginx"
}

build {
    name = "demo-nginx-custom"
    sources = [
        "source.docker.nginx"        # see the definition at the source block
    ]

    provisioner "shell" {
        environment_vars = [
            "DEBIAN_FRONTEND=noninteractive"
        ]

        scripts = [
            "${local.nginx_scripts_dir}/init-apt.sh",
            "${local.nginx_scripts_dir}/install-nginx-packages.sh"
        ]
    }

    // supervisor package must already be installed so /etc/supervisor exists
    provisioner "file" {
        source      = "${local.nginx_scripts_dir}/supervisord.conf"
        destination = "/etc/supervisor/supervisord.conf"
    }

    provisioner "shell" {
        scripts = [
            "${local.nginx_scripts_dir}/cleanup.sh"
        ]
    }

    post-processor "docker-tag" {
        repository = var.nginx_image_name
        tags = [var.image_tag]
    }
}