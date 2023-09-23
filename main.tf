terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.17.0"
    }
  }
  cloud {
    organization = "NAS_Financial"
    workspaces {
    name = "terraform-vpc-nasproject"
    }
}
}

provider "aws" {
  region      = "us-east-1"
  alias       = "use1"
}

module "vpc" {
  source      = "terraform-aws-modules/vpc/aws"
  providers   = {
    aws       = aws.use1
  }
  name        = "nas_vpc"
  cidr        = "10.50.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.50.1.0/24", "10.50.2.0/24", "10.50.3.0/24"]
  public_subnets  = ["10.50.4.0/24", "10.50.5.0/24", "10.50.6.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = false

   tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

# SECUERITY GROUPS - PRIVATE AND PUBLIC
resource "aws_security_group" "nas_frontend_alb_sg" {
  name        = "nas_frontend_alb_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "Allow traffic from public to frontend loadbalancer"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [module.vpc.vpc_cidr_block]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Loadbalancer_fe"
    Tier = "frontend_alb"
    Env = "dev"
  }
}
# DATABASE 
# VPC CREATE