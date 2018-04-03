# Install Drupal 8 on top of Digitalocean LEMP server
This script will remove old php version and install php-7.2, phpmyadmin, composer, Drush 8.x and Drupal-8.5
 

Installation procedure
----------------------
Go to oneclick apps, choose LEMP and create a droplet. SSH your droplet and execute the below command:  
```
wget https://raw.githubusercontent.com/dbjpanda/digitalocean-drupal/7.x/install.sh && chmod +x install.sh && yes "yes" |  ./install.sh
```

Then open your browser and go to the url droplet_ip_address/phpmyadmin, signin and create a database for Drupal. To signin use Default mysql user name 'root' and default mysql password by executing the below command. 
```
cat ~/.digitalocean_password
```

Now go to the url droplet_ip_adress and finish Drupal installation. After successful installation of Drupal don't forget to execute the below command to secure your settings.php: 
```
chmod 644 /var/www/html/drupal/sites/default/settings.php
```
