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
    # Apache package name might be 'httpd' on RHEL/Fedora based systems
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
    # For Fedora/CentOS, the config file may be in a different location
    APACHE_CONF="/etc/httpd/conf/httpd.conf"
    sudo sed -i '/<\/Directory>/i \
<Directory "/var/www/html">\
    AllowOverride All\
</Directory>' "$APACHE_CONF"
fi

# Enable mod_rewrite and restart Apache
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
    eval "$install_cmd php libapache2-mod-php php-mysql php-curl php-gd php-dom php-xml php-cli php-common php-mbstring php-intl php-zip php-xmlrpc"
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
    # For Fedora/RHEL, the package name might be mariadb-server or mysql-server
    eval "$install_cmd mariadb-server"
fi

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
if [ "$pm" == "apt-get" ]; then
    WEB_ROOT="/var/www/html"
else
    # On Fedora/RHEL systems the document root is often /var/www/html as well.
    WEB_ROOT="/var/www/html"
fi
cd "$WEB_ROOT"
sudo wget https://assets.prestashop3.com/dst/edition/corporate/8.1.7/prestashop_edition_basic_version_8.1.7.zip

echo "PrestaShop installation script completed successfully."

eval "$install_cmd unzip"
sudo unzip prestashop_edition_basic_version_8.1.7.zip -d prestashop

# Set correct ownership for the web directory
if [ "$pm" == "apt-get" ]; then
    sudo chown -R www-data:www-data "$WEB_ROOT/prestashop"
else
    # On Fedora/RHEL the Apache user is usually 'apache'
    sudo chown -R apache:apache "$WEB_ROOT/prestashop"
fi
