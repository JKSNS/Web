#!/bin/bash
set -e

echo "== Updating system =="
sudo apt-get update && sudo apt-get upgrade -y

echo "== Installing Apache and PHP modules =="
sudo apt-get install -y apache2 libapache2-mod-php

echo "== Configuring Apache to allow .htaccess overrides =="
# Backup original configuration file
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.bak

# Insert Directory block for /var/www/html before the closing VirtualHost tag
sudo sed -i '/<\/VirtualHost>/i \
<Directory /var/www/html>\n    AllowOverride All\n</Directory>' /etc/apache2/sites-available/000-default.conf

echo "== Enabling mod_rewrite =="
sudo a2enmod rewrite

echo "== Restarting Apache =="
sudo systemctl restart apache2

echo "== Installing PHP and required PHP modules =="
sudo apt-get install -y php libapache2-mod-php
sudo apt-get install -y php-cli php-common php-mbstring php-gd php-intl php-xml php-mysql php-zip php-curl php-xmlrpc

echo "== Restarting Apache again =="
sudo systemctl restart apache2

echo "== Installing MariaDB server =="
sudo apt-get install -y mariadb-server

echo "== Setting up the PrestaShop database =="
sudo mysql -u root <<EOF
CREATE DATABASE prestashop;
CREATE USER 'ps_user'@'localhost' IDENTIFIED BY 'PASSWORD';
GRANT ALL ON prestashop.* TO 'ps_user'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "== Downloading PrestaShop =="
cd /var/www/html
sudo wget https://download.prestashop.com/download/releases/prestashop_1.7.2.1.zip

echo "== Installing unzip utility =="
sudo apt-get install -y unzip

echo "== Extracting PrestaShop package =="
sudo unzip prestashop_1.7.2.1.zip

echo "== Setting permissions for /var/www/html =="
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

echo "== PrestaShop installation script completed =="
