# Frontend ALB
# Backend ALb
# File System (EFS)
# Launch Template
# Auto Scaling Group
# Target Group



# Create a KMS key for EFS encryption
resource "aws_kms_key" "nas_efs_kms_key" {
  description         = "KMS key for EFS encryption"
  enable_key_rotation = true
  policy              = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "AWS": "*"
          },
          "Action": "kms:*",
          "Resource": "*"
        }
      ]
    }
  EOF
  tags = {
    Name = "nas_efs"
    Tier = "backend"
  }
}


# Create an EFS file system with the specified configurations
resource "aws_efs_file_system" "nas_efs" {
  creation_token   = "my-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true
  kms_key_id       = aws_kms_key.nas_efs_kms_key.arn
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }
}
resource "aws_efs_backup_policy" "efs_policy" {
  file_system_id = aws_efs_file_system.nas_efs.id

  backup_policy {
    status = "ENABLED"
  }
}

# Mount targets in different availability zones
resource "aws_efs_mount_target" "mount_target_0" {
  file_system_id  = aws_efs_file_system.nas_efs.id
  security_groups = [aws_security_group.nas_efs_sg.id]
  subnet_id       = module.vpc.private_subnets[0]
}

resource "aws_efs_mount_target" "mount_target_1" {
  file_system_id  = aws_efs_file_system.nas_efs.id
  security_groups = [aws_security_group.nas_efs_sg.id]
  subnet_id       = module.vpc.private_subnets[1]
}

resource "aws_efs_mount_target" "mount_target_2" {
  file_system_id  = aws_efs_file_system.nas_efs.id
  security_groups = [aws_security_group.nas_efs_sg.id]
  subnet_id       = module.vpc.private_subnets[2]
}

# **********************************Load Balancers and target groups Section**************************
# Frontend Target Group Creation
resource "aws_lb_target_group" "nas_frontend_tg" {
  name       = "nas-frontend-tg"   # (_) not accepted here
  target_type = "instance"
  port       = 80        # "443"
  protocol   =  "HTTP"   #"HTTPS"
  vpc_id     = module.vpc.vpc_id
  health_check {
    # enabled             = true
    port                = 80      # "443"
    # interval            = 30
    protocol            = "HTTP"  # "HTTPS"
    path                = "/"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  lifecycle {
    create_before_destroy = false
  }
  tags = {
    Name = "nas_frontend_tg"
    Tier = "frontend"
  }
}
# Frontend Load Balancer Creation
resource "aws_lb" "nas_frontend_alb" {

  name               = "nas-frontend-alb"   # (_) not accepted here
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nas_frontend_alb_sg.id]
  subnets            = [module.vpc.public_subnets[0], module.vpc.public_subnets[1], module.vpc.public_subnets[2]]
  tags = {
    Name = "nas_frontend_alb"
    Tier = "frontend"
  }
}

# ALB Listeners Creation
resource "aws_alb_listener" "frontend_http" {
  depends_on        = [aws_lb_target_group.nas_frontend_tg]
  load_balancer_arn = aws_lb.nas_frontend_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.nas_frontend_tg.arn
    type             = "forward"
  }
}


# resource "aws_lb_listener" "frontend_http" {
#   depends_on        = [aws_lb_target_group.nas_frontend_tg]
#   load_balancer_arn = aws_lb.nas_frontend_alb.arn
#   port              = "80"
#   protocol          = "HTTP"
#     default_action {
#     type = "redirect"
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }
# resource "aws_alb_listener" "frontend_https" {
#   depends_on        = [aws_lb_target_group.nas_frontend_tg]
#   load_balancer_arn = aws_lb.nas_frontend_alb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn = aws_acm_certificate.cert.arn 
#   default_action {
#     target_group_arn = aws_lb_target_group.nas_frontend_tg.arn
#     type             = "forward"
#   }
# }

# Backend Target Group Creation
resource "aws_lb_target_group" "nas_backend_tg" {
  name       = "nas-backend-tg"   # (_) not accepted here
  target_type = "instance"
  port       = 80   #"443"
  protocol   =  "HTTP"     #"HTTPS" 
  vpc_id     = module.vpc.vpc_id
  health_check {
    # enabled             = true
    port                = 80     #"443"
    # interval            = 30
    protocol            = "HTTP" #"HTTPS"
    path                = "/"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  lifecycle {
    create_before_destroy = false
  }
  tags = {
    Name = "nas_backend_tg"
    Tier = "backend"
  }
}
# Backend Load Balancer Creation
resource "aws_lb" "nas_backend_alb" {

  name               = "nas-backend-alb"   # (_) not accepted here
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nas_backend_alb_sg.id]
  subnets            = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
  tags = {
    Name = "nas_backend_alb"
    Tier = "backend"
  }
}

# Backend ALB Listeners Creation
resource "aws_alb_listener" "backend_http" {
  depends_on        = [aws_lb_target_group.nas_backend_tg]
  load_balancer_arn = aws_lb.nas_backend_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.nas_backend_tg.arn
    type             = "forward"
  }
}


# resource "aws_lb_listener" "backend_http" {
#   depends_on        = [aws_lb_target_group.nas_backend_tg]
#   load_balancer_arn = aws_lb.nas_backend_alb.arn
#   port              = "80"
#   protocol          = "HTTP"
#     default_action {
#     type = "redirect"
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }
# resource "aws_alb_listener" "backend_https" {
#   depends_on        = [aws_lb_target_group.nas_backend_tg]
#   load_balancer_arn = aws_lb.nas_backend_alb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn = aws_acm_certificate.cert.arn 
#   default_action {
#     target_group_arn = aws_lb_target_group.nas_backend_tg.arn
#     type             = "forward"
#   }
# }
