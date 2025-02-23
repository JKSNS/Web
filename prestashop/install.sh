#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Optional: Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit 1
fi

# --- Step 1: Update Your System ---
echo "Updating system packages..."
apt-get update && apt-get upgrade -y

# --- Step 2: Install Apache ---
echo "Installing Apache and the PHP Apache module..."
apt-get install -y apache2 libapache2-mod-php

# --- Step 3: Configure Apache for .htaccess Overrides ---
echo "Configuring Apache to allow .htaccess overrides..."
sed -i '/<\/VirtualHost>/i \
<Directory /var/www/html>\
    AllowOverride All\
</Directory>' /etc/apache2/sites-available/000-default.conf

# Enable mod_rewrite and restart Apache
echo "Enabling Apache mod_rewrite module..."
a2enmod rewrite
echo "Restarting Apache..."
systemctl restart apache2

# --- Step 4: Install PHP and Extensions ---
echo "Installing PHP and required extensions..."
apt-get install -y php php-cli php-common php-mbstring php-gd php-intl php-xml php-mysql php-zip php-curl php-xmlrpc
echo "Restarting Apache to load PHP modules..."
systemctl restart apache2

# --- Step 5: Install and Configure MariaDB ---
echo "Installing MariaDB..."
apt-get install -y mariadb-server

echo "Creating the PrestaShop database and user..."
# Replace 'PASSWORD' with a strong password of your choice.
mysql -u root <<EOF
CREATE DATABASE prestashop;
CREATE USER 'ps_user'@'localhost' IDENTIFIED BY 'PASSWORD';
GRANT ALL ON prestashop.* TO 'ps_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# --- Step 6: Download and Extract PrestaShop ---
echo "Downloading PrestaShop..."
cd /var/www/html
wget https://download.prestashop.com/download/releases/prestashop_1.7.2.1.zip

echo "Installing unzip (if not already installed) and extracting PrestaShop..."
apt-get install -y unzip
unzip prestashop_1.7.2.1.zip

# If the archive extracts into a subdirectory, move its contents to the web root.
if [ -d "prestashop" ]; then
  echo "Moving PrestaShop files to /var/www/html..."
  mv prestashop/* .
  rm -rf prestashop
fi

echo "Removing default Apache index file..."
rm -f /var/www/html/index.html

# --- Step 7: Set Directory Ownership and Permissions ---
echo "Assigning correct directory ownership and permissions..."
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

echo "Installation steps complete. Please open your server's public IP in a browser to finalize the PrestaShop setup."
