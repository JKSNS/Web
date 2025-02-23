#!/bin/bash
set -e

echo "== 1. Update and Upgrade System Packages =="
sudo apt-get update && sudo apt-get upgrade -y

echo "== 2. Install Apache and PHP modules =="
sudo apt-get install -y apache2 libapache2-mod-php

echo "== 3. Configure Apache for .htaccess Overrides =="
# Backup the default Apache config
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.bak

# Insert the <Directory> block for /var/www/html if not already present
sudo sed -i '/<\/VirtualHost>/i \
<Directory /var/www/html>\n    AllowOverride All\n</Directory>' /etc/apache2/sites-available/000-default.conf

echo "== 4. Enable mod_rewrite and Restart Apache =="
sudo a2enmod rewrite
sudo systemctl restart apache2

echo "== 5. Install Required PHP Packages =="
sudo apt-get install -y php libapache2-mod-php \
    php-cli php-common php-mbstring php-gd php-intl php-xml \
    php-mysql php-zip php-curl php-xmlrpc

echo "== Restarting Apache after installing PHP packages =="
sudo systemctl restart apache2

echo "== 6. Install MariaDB Server =="
sudo apt-get install -y mariadb-server

echo "== 7. Create PrestaShop Database and User =="
sudo mysql -u root <<EOF
CREATE DATABASE prestashop;
CREATE USER 'ps_user'@'localhost' IDENTIFIED BY 'PASSWORD';
GRANT ALL ON prestashop.* TO 'ps_user'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "== 8. Navigate to /var/www/html =="
cd /var/www/html

echo "== 9. Remove/Rename Default index.html if it Exists =="
if [ -f "index.html" ]; then
    sudo mv index.html index.html.bak
fi

echo "== 10. Install unzip if not present =="
sudo apt-get install -y unzip

echo "== 11. Download (If Needed) and Unzip PrestaShop =="
# If you haven't already downloaded PrestaShop, you can do so here.
# Uncomment the line below if needed:
# sudo wget https://download.prestashop.com/download/releases/prestashop_1.7.2.1.zip

# Adjust the ZIP filename as needed:
sudo unzip -o prestashop_1.7.2.1.zip

echo "== 12. Set Proper Permissions =="
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

echo "== 13. Restart Apache to Finalize Changes =="
sudo systemctl restart apache2

echo "========================================"
echo "PrestaShop installation script complete!"
echo "========================================"
echo "Next steps:"
echo " 1. Open your browser at http://YOUR_SERVER_IP/ (or domain)"
echo " 2. Follow the on-screen PrestaShop installer"
echo " 3. Use the database name 'prestashop', user 'ps_user', and the password you set above"
echo " 4. After installation, remove or rename the /install folder as prompted."
