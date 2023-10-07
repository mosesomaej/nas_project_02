# VPC
variable "vpc_cidr" {
    type = string
    default = "10.50.0.0/16"
    description = "VPC cidr block"
}

variable "key_name" {
    type = string
    default = "nas_frontend_keypair"
    description = "nas_frontend_keypair"
}