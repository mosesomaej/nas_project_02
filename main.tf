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
  alias = "use1"
}

# VPC CREATE AND OTHERS
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  providers = {
    aws = aws.use1
  }
  name = "nas_vpc"
  cidr = "10.50.0.0/16"

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

resource "aws_security_group" "nas_frontend_sg" {
  
}