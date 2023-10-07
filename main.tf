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