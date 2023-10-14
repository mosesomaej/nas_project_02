resource "aws_iam_instance_profile" "nas_instance_profile" {
  name = "nas-instance-profile"
  role = aws_iam_role.nas_instance_role.name
}

resource "aws_iam_role" "nas_instance_role" {
  name = "nas-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "example_policy" {
  name = "example-policy"

  # Define your policy document here. This is just an example policy; modify it to fit your needs.
  description = "An example IAM policy for EC2 instances"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          ""
        ],
        Effect   = "Allow",
        Resource = [
          "arn:aws:s3:::example-bucket/*",
          "arn:aws:s3:::example-bucket",
        ],
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "example_attachment" {
  policy_arn = aws_iam_policy.example_policy.arn
  role       = aws_iam_role.example_role.name
}

# # Attach AmazonSSMManagedInstanceCore policy to the IAM role
# resource "aws_iam_role_policy_attachment" "ec2_role_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   role       = aws_iam_role.ec2_role.name
# }

# # Create an instance profile for the EC2 instance and associate the IAM role
# resource "aws_iam_instance_profile" "ec2_instance_profile" {
#   name = "EC2_SSM_Instance_Profile"

#   role = "aws_iam_role.ec2_role.name"
# }