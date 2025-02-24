#!/bin/bash
set -e

function detect_system_info {
    echo "Detecting system info..."
    echo "[*] Detecting package manager"

    if command -v apt-get &> /dev/null; then
        echo "[*] apt/apt-get detected (Debian-based OS)"
        pm="apt-get"
        update_cmd="sudo apt update && sudo apt upgrade -y"
        install_cmd="sudo apt install -y"
    elif command -v dnf &> /dev/null; then
        echo "[*] dnf detected (Fedora-based OS)"
        pm="dnf"
        update_cmd="sudo dnf update -y"
        install_cmd="sudo dnf install -y"
    elif command -v zypper &> /dev/null; then
        echo "[*] zypper detected (OpenSUSE-based OS)"
        pm="zypper"
        update_cmd="sudo zypper refresh"
        install_cmd="sudo zypper install -y"
    elif command -v yum &> /dev/null; then
        echo "[*] yum detected (RHEL-based OS)"
        pm="yum"
        update_cmd="sudo yum update -y"
        install_cmd="sudo yum install -y"
    else
        echo "[X] ERROR: Could not detect package manager"
        exit 1
    fi

    echo "[*] Using package manager: $pm"
}

# Helper function to configure php.ini
function configure_php_ini {
    echo "Configuring php.ini to hide deprecation notices..."

    if [ "$pm" == "apt-get" ]; then
        # For Debian/Ubuntu: look under /etc/php/*/apache2/php.ini
        for ini_file in /etc/php/*/apache2/php.ini; do
            if [ -f "$ini_file" ]; then
                echo "Updating $ini_file..."
                sudo sed -i "s|^error_reporting = .*|error_reporting = E_ALL & ~E_DEPRECATED & ~E_NOTICE|" "$ini_file"
                sudo sed -i "s|^display_errors = .*|display_errors = Off|" "$ini_file"
            fi
        done
        # Reload Apache to apply changes
        sudo systemctl reload apache2 || sudo systemctl restart apache2

    else
        # For Fedora/RHEL: default /etc/php.ini
        if [ -f /etc/php.ini ]; then
            echo "Updating /etc/php.ini..."
            sudo sed -i "s|^error_reporting = .*|error_reporting = E_ALL & ~E_DEPRECATED & ~E_NOTICE|" /etc/php.ini
            sudo sed -i "s|^display_errors = .*|display_errors = Off|" /etc/php.ini
            # Reload/restart httpd to apply changes
            sudo systemctl reload httpd || sudo systemctl restart httpd
        fi
    fi
}

# 1. Detect system info
detect_system_info

# 2. Update/upgrade system
echo "Updating system..."
eval "$update_cmd"

# 3. Install Apache
echo "Installing Apache..."
if [ "$pm" == "apt-get" ]; then
    eval "$install_cmd apache2"
else
    # On Fedora/RHEL, Apache is typically named httpd
    if [ "$pm" == "dnf" ] || [ "$pm" == "yum" ]; then
        eval "$install_cmd httpd"
    else
        eval "$install_cmd apache2"
    fi
fi

# 4. Configure Apache to allow .htaccess
echo "Configuring Apache..."
if [ "$pm" == "apt-get" ]; then
    APACHE_CONF="/etc/apache2/sites-available/000-default.conf"
    sudo sed -i '/<\/VirtualHost>/i \
<Directory /var/www/html>\
    AllowOverride All\
</Directory>' "$APACHE_CONF"
else
    # For Fedora/RHEL, typically /etc/httpd/conf/httpd.conf
    APACHE_CONF="/etc/httpd/conf/httpd.conf"
    sudo sed -i '/<\/Directory>/i \
<Directory "/var/www/html">\
    AllowOverride All\
</Directory>' "$APACHE_CONF"
fi

# 5. Enable mod_rewrite (Debian/Ubuntu) and restart Apache
echo "Enabling mod_rewrite..."
if [ "$pm" == "apt-get" ]; then
    sudo a2enmod rewrite
fi

if [ "$pm" == "apt-get" ]; then
    sudo systemctl restart apache2
else
    sudo systemctl restart httpd
fi

# 6. Install PHP & extensions
echo "Installing PHP and required modules..."
if [ "$pm" == "apt-get" ]; then
    eval "$install_cmd php libapache2-mod-php php-cli php-common php-mbstring php-gd php-intl php-xml php-mysql php-zip php-curl php-xmlrpc"
else
    # Adjust as necessary for Fedora/RHEL
    eval "$install_cmd php php-mysqlnd php-curl php-gd php-xml php-cli php-mbstring"
fi

# Restart Apache to load PHP modules
if [ "$pm" == "apt-get" ]; then
    sudo systemctl restart apache2
else
    sudo systemctl restart httpd
fi

# 7. Install MariaDB
echo "Installing MariaDB server..."
if [ "$pm" == "apt-get" ]; then
    eval "$install_cmd mariadb-server"
else
    eval "$install_cmd mariadb-server"
fi

# Secure MariaDB installation (optional)
# sudo mysql_secure_installation

# 8. Create OpenCart database and user
echo "Creating the OpenCart database and user..."
sudo mysql -u root <<EOF
CREATE DATABASE opencartdb;
CREATE USER 'opencart_user'@'localhost' IDENTIFIED BY 'PASSWORD';
GRANT ALL ON opencartdb.* TO 'opencart_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# 9. Download OpenCart
echo "Downloading OpenCart..."
WEB_ROOT="/var/www/html"
cd "$WEB_ROOT"

sudo wget https://github.com/opencart/opencart/releases/download/3.0.2.0/3.0.2.0-OpenCart.zip

# 10. Unzip OpenCart
echo "Installing unzip if needed..."
eval "$install_cmd unzip"

echo "Unzipping OpenCart to 'opencart' folder..."
sudo unzip 3.0.2.0-OpenCart.zip -d opencart

# 11. Rename config-dist.php to config.php
echo "Renaming config-dist.php to config.php..."
sudo cp opencart/upload/config-dist.php opencart/upload/config.php
sudo cp opencart/upload/admin/config-dist.php opencart/upload/admin/config.php

# 12. Set correct permissions and ownership
echo "Setting correct permissions..."
sudo chmod -R 755 "$WEB_ROOT/opencart"

if [ "$pm" == "apt-get" ]; then
    sudo chown -R www-data:www-data "$WEB_ROOT/opencart"
else
    sudo chown -R apache:apache "$WEB_ROOT/opencart"
fi

# 13. Configure php.ini to hide deprecated warnings
configure_php_ini

echo "OpenCart installation script completed successfully."
echo "Next steps:"
echo "1) Navigate to http://YOUR_SERVER_IP/opencart/upload/ to run the OpenCart installer."
echo "2) Provide the database info (opencartdb, opencart_user, PASSWORD)."
echo "3) Once done, remove or rename the 'install' folder as prompted by OpenCart."
echo "4) Admin panel: http://YOUR_SERVER_IP/opencart/upload/admin/"
