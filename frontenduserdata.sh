#!/bin/bash
    sudo su
    yum update -y
    yum install jq -y && yum install awscli -y
    mkdir /var/www/ && mkdir /var/www/html
    sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_dns_name}:/ /var/www/html/
    yum install -y amazon-efs-utils
    echo "${efs_dns_name} :/ /var/www/html/ efs defaults,_netdev 0 0" >> /etc/fstab
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    systemctl status httpd
    wget https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz
    cp -r wordpress/* /var/www/html/
    cp wordpress/wp-config-sample.php /var/www/html/wp-config.php
    # sed -i "s/database_name_here/${aws_rds_cluster.nas_db.database_name}/g" /var/www/html/wp-config.php
    # sed -i "s/username_here/${aws_rds_cluster.nas_db.master_username}/g" /var/www/html/wp-config.php
    # sed -i "s/password_here/${DBPassword}/g" /var/www/html/wp-config.php
    # sed -i "s/localhost/${NasDb.Endpoint.Address}/g" /var/www/html/wp-config.php
    amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
    systemctl restart httpd