# VPC
variable "vpc_cidr" {
    type = string
    default = "10.50.0.0/16"
    description = "VPC cidr block"
}