# Global stuff

variable "scripts_root" {
    type    = string
    default = "packer/scripts"
}

# Base image

variable "base_image_name" {
    type    = string
    default = env("BASE_IMAGE_NAME")
}

variable "image_tag" {
    type    = string
    default = env("IMAGE_TAG")
}

# Postgres image

variable "postgres_image_name" {
    type = string
    default = env("POSTGRES_IMAGE_NAME")
}

# nginx image
variable "nginx_image_name" {
    type = string
    default = env("NGINX_IMAGE_NAME")
}

# apache image
variable "apache_image_name" {
    type = string
    default = env("APACHE_IMAGE_NAME")
}

# ansible bastion image
variable "bastion_image_name" {
    type = string
    default = env("BASTION_IMAGE_NAME")
}

# Java API endpoint image
variable "api_image_name" {
    type = string
    default = env("API_IMAGE_NAME")
}