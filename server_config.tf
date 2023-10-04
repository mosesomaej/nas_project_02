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



