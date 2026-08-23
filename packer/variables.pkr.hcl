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