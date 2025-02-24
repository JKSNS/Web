#!/bin/bash
set -e

# Update and upgrade system packages
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# Install Apache
echo "Installing Apache..."
sudo apt install apache2 -y

# Configure Apache to allow .htaccess overrides
echo "Configuring Apache..."
APACHE_CONF="/etc/apache2/sites-available/000-default.conf"
sudo sed -i '/<\/VirtualHost>/i \
<Directory /var/www/html>\
    AllowOverride All\
</Directory>' "$APACHE_CONF"

# Enable mod_rewrite
echo "Enabling mod_rewrite..."
sudo a2enmod rewrite
sudo systemctl restart apache2

# Install PHP and required extensions
echo "Installing PHP and required modules..."
sudo apt install -y \
    php libapache2-mod-php php-mysql php-curl php-gd php-dom php-xml \
    php-cli php-common php-mbstring php-intl php-zip php-xmlrpc

# Restart Apache to load PHP modules
sudo systemctl restart apache2

# Install MariaDB server
echo "Installing MariaDB server..."
sudo apt-get install mariadb-server -y

# Secure MariaDB installation (optional)
# Uncomment the next line if you want to run the secure installation script interactively.
# sudo mysql_secure_installation

echo "Creating the PrestaShop database and user..."
# Replace 'PASSWORD' below with a strong password of your choice
sudo mysql -u root <<EOF
CREATE DATABASE prestashop;
CREATE USER 'ps_user'@'localhost' IDENTIFIED BY 'PASSWORD';
GRANT ALL ON prestashop.* TO 'ps_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Change directory to Apache web root and download PrestaShop
echo "Downloading PrestaShop..."
cd /var/www/html
sudo wget https://assets.prestashop3.com/dst/edition/corporate/8.1.7/prestashop_edition_basic_version_8.1.7.zip

echo "PrestaShop installation script completed successfully."

sudo apt install unzip -y
sudo unzip prestashop_edition_basic_version_8.1.7.zip -d prestashop

sudo chown -R www-data:www-data /var/www/html/prestashop

