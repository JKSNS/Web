#!/bin/bash

# Update package list and install required packages
apt update -y
apt install -y apache2 php libapache2-mod-php php-mysql php-gd php-mbstring php-zip php-curl php-xml unzip mariadb-server

# Start and enable services
systemctl start apache2
systemctl enable apache2
systemctl start mariadb
systemctl enable mariadb

# Secure MySQL installation and set root password
mysql -e "UPDATE mysql.user SET Password=PASSWORD('rootpass') WHERE User='root';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "FLUSH PRIVILEGES;"

# Create PrestaShop database and user
mysql -uroot -prootpass -e "CREATE DATABASE prestashop_db;"
mysql -uroot -prootpass -e "CREATE USER 'prestashop_user'@'localhost' IDENTIFIED BY 'pspass';"
mysql -uroot -prootpass -e "GRANT ALL PRIVILEGES ON prestashop_db.* TO 'prestashop_user'@'localhost';"
mysql -uroot -prootpass -e "FLUSH PRIVILEGES;"

# Download and extract PrestaShop (using a stable version as of Feb 2025)
cd /var/www/html
wget https://github.com/PrestaShop/PrestaShop/releases/download/8.1.2/prestashop_8.1.2.zip -O prestashop.zip
unzip prestashop.zip
unzip prestashop_*.zip # Extracts the inner zip file
mv prestashop prestashop_files # Rename for clarity
rm -f prestashop.zip prestashop_*.zip index.html

# Set permissions
chown -R www-data:www-data /var/www/html/prestashop_files
chmod -R 755 /var/www/html/prestashop_files

# Configure Apache
cat > /etc/apache2/sites-available/prestashop.conf << EOL
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/prestashop_files
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Enable site and restart Apache
a2ensite prestashop.conf
a2enmod rewrite
systemctl restart apache2

# Output instructions
echo "PrestaShop is installed. Access it at http://your_server_ip/"
echo "Complete the installation via the web interface:"
echo "Database Name: prestashop_db"
echo "Database User: prestashop_user"
echo "Database Password: pspass"
echo "MySQL Root Password: rootpass"
