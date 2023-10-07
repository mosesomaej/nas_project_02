#!/bin/bash
yum update -y
yum install -y httpd
systemctl enable httpd
systemctl start httpd
echo "Hello from Terraform! Welcome to NAS Financial Group Website" > /var/www/html/index.html