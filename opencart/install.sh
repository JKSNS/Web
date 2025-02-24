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

# Detect the system info and set package manager variables
detect_system_info

# Update and upgrade system packages
echo "Updating system..."
eval "$update_cmd"

# Install Apache
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

# Configure Apache to allow .htaccess overrides
echo "Configuring Apache..."
if [ "$pm" == "apt-get" ]; then
    APACHE_CONF="/etc/apache2/sites-available/000-default.conf"
    sudo sed -i '/<\/VirtualHost>/i \
<Directory /var/www/html>\
    AllowOverride All\
</Directory>' "$APACHE_CONF"
else
    # For Fedora/RHEL, the main config is often /etc/httpd/conf/httpd.conf
    APACHE_CONF="/etc/httpd/conf/httpd.conf"
    sudo sed -i '/<\/Directory>/i \
<Directory "/var/www/html">\
    AllowOverride All\
</Directory>' "$APACHE_CONF"
fi

# Enable mod_rewrite (Debian/Ubuntu) and restart Apache
echo "Enabling mod_rewrite..."
if [ "$pm" == "apt-get" ]; then
    sudo a2enmod rewrite
fi

if [ "$pm" == "apt-get" ]; then
    sudo systemctl restart apache2
else
    sudo systemctl restart httpd
fi

# Install PHP and required extensions
echo "Installing PHP and required modules..."
if [ "$pm" == "apt-get" ]; then
    eval "$install_cmd php libapache2-mod-php php-cli php-common php-mbstring php-gd php-intl php-xml php-mysql php-zip php-curl php-xmlrpc"
else
    # Package names may vary; adjust accordingly for your distro.
    # This example is for Fedora/RHEL-like systems.
    eval "$install_cmd php php-mysqlnd php-curl php-gd php-xml php-cli php-mbstring"
fi

# Restart Apache to load PHP modules
if [ "$pm" == "apt-get" ]; then
    sudo systemctl restart apache2
else
    sudo systemctl restart httpd
fi

# Install MariaDB server
echo "Installing MariaDB server..."
if [ "$pm" == "apt-get" ]; then
    eval "$install_cmd mariadb-server"
else
    # For Fedora/RHEL, package name might be mariadb-server or mysql-server
    eval "$install_cmd mariadb-server"
fi

# Secure MariaDB installation (optional)
# Uncomment the next line if you want to run the secure installation script interactively.
# sudo mysql_secure_installation

echo "Creating the OpenCart database and user..."
# Replace 'PASSWORD' with a strong password of your choice
sudo mysql -u root <<EOF
CREATE DATABASE opencartdb;
CREATE USER 'opencart_user'@'localhost' IDENTIFIED BY 'PASSWORD';
GRANT ALL ON opencartdb.* TO 'opencart_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Change directory to Apache web root and download OpenCart
echo "Downloading OpenCart..."
if [ "$pm" == "apt-get" ]; then
    WEB_ROOT="/var/www/html"
else
    # On Fedora/RHEL systems the document root is often /var/www/html as well.
    WEB_ROOT="/var/www/html"
fi
cd "$WEB_ROOT"

sudo wget https://github.com/opencart/opencart/releases/download/3.0.2.0/3.0.2.0-OpenCart.zip

echo "OpenCart installation script completed successfully."

# Install unzip if not already present
eval "$install_cmd unzip"

# Unzip OpenCart into a folder named 'opencart'
sudo unzip 3.0.2.0-OpenCart.zip -d opencart

# OPTIONAL: If you want to copy the content of `upload/` to the main opencart folder:
# sudo cp -R opencart/upload/* opencart/

# Set correct permissions and ownership for the web directory
sudo chmod -R 755 "$WEB_ROOT/opencart"
if [ "$pm" == "apt-get" ]; then
    sudo chown -R www-data:www-data "$WEB_ROOT/opencart"
else
    # On Fedora/RHEL the Apache user is usually 'apache'
    sudo chown -R apache:apache "$WEB_ROOT/opencart"
fi
