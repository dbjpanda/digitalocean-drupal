#!/bin/bash

sudo apt-get update

truncate -s 0 /etc/nginx/sites-available/digitalocean
cat > /etc/nginx/sites-available/digitalocean<<'EOF'
server {
    server_name default_server;
    root /var/www/html/drupal; ## <-- Your only path reference.

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # Very rarely should these ever be accessed outside of your lan
    location ~* \.(txt|log)$ {
        allow 192.168.0.0/16;
        deny all;
    }

    location ~ \..*/.*\.php$ {
        return 403;
    }

    location ~ ^/sites/.*/private/ {
        return 403;
    }

    # Allow "Well-Known URIs" as per RFC 5785
    location ~* ^/.well-known/ {
        allow all;
    }

    # Block access to "hidden" files and directories whose names begin with a
    # period. This includes directories used by version control systems such
    # as Subversion or Git to store control files.
    location ~ (^|/)\. {
        return 403;
    }

    location / {
        # try_files $uri @rewrite; # For Drupal <= 6
        try_files $uri /index.php?$query_string; # For Drupal >= 7
    }

    location @rewrite {
        rewrite ^/(.*)$ /index.php?q=$1;
    }

    # Don't allow direct access to PHP files in the vendor directory.
    location ~ /vendor/.*\.php$ {
        deny all;
        return 404;
    }

    
    location ~ '\.php$|^/update.php' {
        fastcgi_split_path_info ^(.+?\.php)(|/.*)$;
        include fastcgi_params;
        fastcgi_param HTTP_PROXY "";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param QUERY_STRING $query_string;
        fastcgi_intercept_errors on;
        fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
        
    }

    # Fighting with Styles? This little gem is amazing.
    # location ~ ^/sites/.*/files/imagecache/ { # For Drupal <= 6
    location ~ ^/sites/.*/files/styles/ { # For Drupal >= 7
        try_files $uri @rewrite;
    }

    # Handle private files through Drupal. Private file's path can come
    # with a language prefix.
    location ~ ^(/[a-z\-]+)?/system/files/ { # For Drupal >= 7
        try_files $uri /index.php?$query_string;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        try_files $uri @rewrite;
        expires max;
        log_not_found off;
    }

    #Phpmyadmin Configurations
    location /phpmyadmin {
           root /usr/share/;
           index index.php index.html index.htm;
           location ~ ^/phpmyadmin/(.+\.php)$ {
                   try_files $uri =404;
                   root /usr/share/;
                   fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
                   fastcgi_index index.php;
                   fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                   include /etc/nginx/fastcgi_params;
           }
           location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
                   root /usr/share/;
           }
    }

    
}

EOF


sudo apt-get install php7.0-dom php7.0-gd php7.0-mbstring
cd /var/www/html
wget https://ftp.drupal.org/files/projects/drupal-7.58.tar.gz
tar xzvf drupal*
mkdir drupal
mv -v drupal*/*  drupal/
mkdir /var/www/html/drupal/sites/default/files
cp /var/www/html/drupal/sites/default/default.settings.php /var/www/html/drupal/sites/default/settings.php
sudo chown -R :www-data /var/www/html/drupal/*
chmod -R 777  /var/www/html/drupal/sites/default/files
chmod 664 /var/www/html/drupal/sites/default/settings.php

#install phpmyadmin
wget https://files.phpmyadmin.net/phpMyAdmin/4.7.9/phpMyAdmin-4.7.9-all-languages.zip
sudo apt-get install unzip
unzip phpMyAdmin-4.7.9-all-languages.zip
mv phpMyAdmin-4.7.9-all-languages /usr/share/phpmyadmin

#install composer and Drush
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
wget -O drush.phar https://github.com/drush-ops/drush-launcher/releases/download/0.6.0/drush.phar
chmod +x drush.phar
sudo mv drush.phar /usr/local/bin/drush
cd drupal
composer require drush/drush:8.*

sudo service php7.0-fpm restart
sudo service nginx restart
