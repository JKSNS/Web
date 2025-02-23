#!/bin/bash
# PrestaShop Installation Script for Ubuntu 18.04

# Exit immediately if a command exits with a non-zero status
set -e

# --- Step 1: Update Your System ---
echo "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# --- Step 2: Install Apache ---
echo "Installing Apache and the PHP Apache module..."
sudo apt-get install -y apache2 libapache2-mod-php

# --- Step 3: Configure Apache for .htaccess Overrides ---
echo "Configuring Apache to allow .htaccess overrides..."
# Insert the <Directory> block before the closing </VirtualHost> tag
sudo sed -i '/<\/VirtualHost>/i \
<Directory /var/www/html>\
    AllowOverride All\
</Directory>' /etc/apache2/sites-available/000-default.conf

# Enable mod_rewrite and restart Apache
echo "Enabling Apache mod_rewrite module..."
sudo a2enmod rewrite
echo "Restarting Apache..."
sudo systemctl restart apache2

# --- Step 4: Install PHP and Extensions ---
echo "Installing PHP and required extensions..."
sudo apt install -y php libapache2-mod-php
sudo apt-get install -y php-cli php-common php-mbstring php-gd php-intl php-xml php-mysql php-zip php-curl php-xmlrpc
echo "Restarting Apache to load PHP modules..."
sudo systemctl restart apache2

# --- Step 5: Install ---
echo "Installing MariaDB..."
sudo apt-get install -y mariadb-server

# 1. Create the PrestaShop database
sudo mysql -u root -p -e "CREATE DATABASE prestashop;"

# 2. Create the ps_user user and set password
sudo mysql -u root -p -e "CREATE USER 'ps_user'@'localhost' IDENTIFIED BY 'prestashop';"

# 3. Grant privileges to ps_user on the prestashop database
sudo mysql -u root -p -e "GRANT ALL ON prestashop.* TO 'ps_user'@'localhost';"

# 4. Flush privileges
sudo mysql -u root -p -e "FLUSH PRIVILEGES;"


# --- Step 6: Download and Extract PrestaShop ---
echo "Downloading PrestaShop..."
cd /var/www/html
sudo wget https://download.prestashop.com/download/releases/prestashop_1.7.2.1.zip

echo "Installing unzip (if not already installed) and extracting PrestaShop..."
sudo apt-get install -y unzip
sudo unzip prestashop_1.7.2.1.zip

echo "Removing default Apache index file..."
sudo rm -f /var/www/html/index.html

# --- Step 7: Set Directory Ownership and Permissions ---
echo "Assigning correct directory ownership and permissions..."
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

echo "Installation steps complete. Please open your server's public IP in a browser to finalize the PrestaShop setup."
