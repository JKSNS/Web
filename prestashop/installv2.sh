#!/bin/bash
set -e

# Update and upgrade system packages
echo "Updating system..."
apt update -y && apt upgrade -y

# Install required packages (Apache, PHP, MariaDB, and unzip)
echo "Installing required packages..."
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

# Ensure MySQL root user has proper privileges (fix for ERROR 1356)
mysql -uroot -prootpass -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;"
mysql -uroot -prootpass -e "FLUSH PRIVILEGES;"

# Create PrestaShop database and user with explicit root login
echo "Setting up the database..."
mysql -uroot -prootpass -e "CREATE DATABASE prestashop;"
mysql -uroot -prootpass -e "CREATE USER 'ps_user'@'localhost' IDENTIFIED BY 'password';"
mysql -uroot -prootpass -e "GRANT ALL PRIVILEGES ON prestashop.* TO 'ps_user'@'localhost';"
mysql -uroot -prootpass -e "FLUSH PRIVILEGES;"

# Change directory to Apache web root and download PrestaShop
echo "Downloading PrestaShop..."
cd /var/www/html
wget https://github.com/PrestaShop/PrestaShop/releases/download/8.1.2/prestashop_8.1.2.zip -O prestashop.zip

# Unzip PrestaShop
echo "Unzipping PrestaShop..."
unzip prestashop.zip
unzip prestashop_*.zip  # Extracts the inner zip file (PrestaShop archives often have nested zips)
mv prestashop prestashop_files  # Rename for clarity
rm -f prestashop.zip prestashop_*.zip

# Remove default Apache index.html to prevent it from overriding PrestaShop
rm -f /var/www/html/index.html

# Set permissions for Apache
echo "Setting permissions..."
chown -R www-data:www-data /var/www/html/prestashop_files
chmod -R 755 /var/www/html/prestashop_files

# Configure Apache to allow .htaccess overrides and serve PrestaShop
echo "Configuring Apache..."
cat > /etc/apache2/sites-available/prestashop.conf << EOL
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/prestashop_files
    <Directory /var/www/html/prestashop_files>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Disable default Apache site and enable PrestaShop site
a2dissite 000-default.conf
a2ensite prestashop.conf
a2enmod rewrite

# Restart Apache to apply changes
systemctl restart apache2

# Verify Apache configuration
apache2ctl configtest

# Output instructions
echo "PrestaShop is installed. Access it at http://your_server_ip/"
echo "Complete the installation via the web interface:"
echo "Database Name: prestashop"
echo "Database User: ps_user"
echo "Database Password: password"
echo "MySQL Root Password: rootpass"
