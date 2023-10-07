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
  # engineering_subnets = ["10.50.7.0/24", "10.50.8.0/24", "10.50.9.0/24"] # subnet for engineers

  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = false

   tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

# creating engineering subnet for maintainance purpose
resource "aws_subnet" "engineering_subnets" {
  vpc_id          = module.vpc.vpc_id
  cidr_block      = "10.50.7.0/24"

  tags = {
    Name = "Engineering_subnet"
    Tier = "backend"
  }
}
# SECUERITY GROUPS - PRIVATE AND PUBLIC
# Engineering Team security Group - this will allow only members of the team to have ssh access to others servers
resource "aws_security_group" "engineering_team_sg" {
  name        = "nas_engineering_team_alb_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "Allow enginneers "
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [module.vpc.vpc_cidr_block]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description      = "Allow enginneers "
    from_port        = 443
    to_port          = 443
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
    Name = "Engineering_team_sg"
    Tier = "backend"
    Env = "dev"
  }
}
# Frontend LoadBalancer
resource "aws_security_group" "nas_frontend_alb_sg" {
  name        = "nas_frontend_alb_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "Allow http traffic from public to frontend loadbalancer"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description      = "Allow https traffic from public to frontend loadbalancer"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
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
    Name = "Loadbalancer_frondend_sg"
    Tier = "frontend"
    Env = "dev"
  }
}
# Frontend Webserver Security Group
resource "aws_security_group" "nas_frontend_web_sg" {
  name        = "nas_frontend_web_sg"
  description = "Allow TLS inbound traffic from frontend loadbalancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "Allow https traffic from frontend loadbalancer"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups = [aws_security_group.nas_frontend_alb_sg.id]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description      = "Allow engineering team to ssh into webservers for maintenance purpose"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups = [aws_security_group.engineering_team_sg.id]
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
    Name = "Webserver_frondend_sg"
    Tier = "frontend"
    Env = "dev"
  }
}
# Backend Application Load Balancer Security Group
resource "aws_security_group" "nas_backend_alb_sg" {
  name        = "nas_backend_alb_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "Allow http traffic from public to frontend loadbalancer"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["10.50.0.0/16"]
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
    Name = "Loadbalancer_backend_sg"
    Tier = "backend"
    Env = "dev"
  }
}

# Backend Application Load Balancer Security Group
resource "aws_security_group" "nas_backend_web_sg" {
  name        = "nas_backend_web_sg"
  description = "Allow TLS inbound traffic from backend loadbalancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "Allow https traffic from frontend loadbalancer"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups = [aws_security_group.nas_backend_alb_sg.id]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description      = "Allow engineering team to ssh into webservers"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups = [aws_security_group.engineering_team_sg.id]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  tags = {
    Name = "Webserver_backend_sg"
    Tier = "backend"
    Env = "dev"
  }
}
# Relational Database Security Group
resource "aws_security_group" "nas_rds_sg" {
  name        = "nas_rds_sg"
  description = "Allow TLS inbound traffic from backend webserver" # and frontend webserver?
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "Allow https traffic from frontend loadbalancer" # is it not from frontend and backend webservers?
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups = [aws_security_group.nas_backend_web_sg.id, aws_security_group.nas_frontend_web_sg.id]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  tags = {
    Name = "Database_sg"
    Tier = "backend" # How about frontend?
    Env = "dev"
  }
}

# Database Subnet Group
resource "aws_db_subnet_group" "nas_db_subnet_group" {
  name       = "nas_dev_db_subnet_group"
  subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]

  tags = {
    Name = "DB subnet group"
  }
}

# Elastic File System Security Group
resource "aws_security_group" "nas_efs_sg" {
  name        = "nas_efs_sg"
  description = "Allow TLS inbound traffic from frontend and backend webservers"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "Allow https traffic from frontend and backend webservers"
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    security_groups = [aws_security_group.nas_frontend_web_sg.id, aws_security_group.nas_backend_web_sg.id]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  tags = {
    Name = "Webserver_backend_sg"
    Tier = "backend"
    Env = "dev"
  }
}

# Auditor Security Group
# resource "aws_security_group" "nas_auditor_sg" {
#   name        = "nas_auditor_sg"
#   description = "Allow TLS inbound traffic from auditors network"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description      = "Allow https traffic from auditors"
#     from_port        = 80
#     to_port          = 80
#     protocol         = "tcp"
#     cidr_blocks      = [module.vpc]
#     # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
#   }
#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     # ipv6_cidr_blocks = ["::/0"]
#   }

#   tags = {
#     Name = "Webserver_backend_sg"
#     Tier = "backend"
#     Env = "dev"
#   }
# }