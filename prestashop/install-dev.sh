#!/bin/bash
set -e

# --- Functions for error checking and troubleshooting ---

# Detect system info and set package manager and Apache variables
function detect_system_info {
    echo "Detecting system info..."
    echo "[*] Detecting package manager"

    if command -v apt-get &> /dev/null; then
        echo "[*] apt/apt-get detected (Debian-based OS)"
        pm="apt-get"
        update_cmd="sudo apt update && sudo apt upgrade -y"
        install_cmd="sudo apt install -y"
        apache_user="www-data"
        apache_service="apache2"
        apache_conf="/etc/apache2/sites-available/000-default.conf"
    elif command -v dnf &> /dev/null; then
        echo "[*] dnf detected (Fedora-based OS)"
        pm="dnf"
        update_cmd="sudo dnf update -y"
        install_cmd="sudo dnf install -y"
        apache_user="apache"
        apache_service="httpd"
        apache_conf="/etc/httpd/conf/httpd.conf"
    elif command -v zypper &> /dev/null; then
        echo "[*] zypper detected (OpenSUSE-based OS)"
        pm="zypper"
        update_cmd="sudo zypper refresh"
        install_cmd="sudo zypper install -y"
        apache_user="www-data"
        apache_service="apache2"
        apache_conf="/etc/apache2/sites-available/000-default.conf"
    elif command -v yum &> /dev/null; then
        echo "[*] yum detected (RHEL-based OS)"
        pm="yum"
        update_cmd="sudo yum update -y"
        install_cmd="sudo yum install -y"
        apache_user="apache"
        apache_service="httpd"
        apache_conf="/etc/httpd/conf/httpd.conf"
    else
        echo "[X] ERROR: Could not detect package manager"
        exit 1
    fi

    echo "[*] Using package manager: $pm"
}

# Check if a service is running; if not, try restarting it
function check_service_running {
    service_name="$1"
    echo "Checking if $service_name is running..."
    if systemctl is-active --quiet "$service_name"; then
        echo "[*] $service_name is running."
    else
        echo "[X] ERROR: $service_name is not running. Attempting restart..."
        sudo systemctl restart "$service_name"
        sleep 3
        if systemctl is-active --quiet "$service_name"; then
            echo "[*] $service_name restarted successfully."
        else
            echo "[X] ERROR: Failed to start $service_name. Exiting."
            exit 1
        fi
    fi
}

# Check the installed PHP version
function check_php_version {
    echo "Checking PHP version..."
    php_ver=$(php -v | head -n 1)
    echo "[*] PHP version: $php_ver"
}

# Check if a required PHP module is installed
function check_php_module {
    mod="$1"
    echo "Checking for PHP module: $mod..."
    if php -m | grep -q "^$mod$"; then
        echo "[*] PHP module $mod is installed."
    else
        echo "[X] ERROR: PHP module $mod is missing. Exiting."
        exit 1
    fi
}

# Check file permission against an expected numeric value (e.g. 644, 755)
function check_file_permission {
    file="$1"
    expected="$2"  # Expected permission, e.g., 644
    actual=$(stat -c "%a" "$file")
    if [ "$actual" == "$expected" ]; then
        echo "[*] $file has correct permission $expected."
    else
        echo "[X] ERROR: $file permission is $actual, expected $expected."
        exit 1
    fi
}

# --- Main script execution ---

# Detect system info and set related variables
detect_system_info

# Update and upgrade system packages
echo "Updating system..."
eval "$update_cmd"

# Install Apache
echo "Installing Apache..."
if [ "$pm" == "apt-get" ]; then
    eval "$install_cmd apache2"
else
    # On Fedora/RHEL, Apache is typically known as 'httpd'
    if [ "$pm" == "dnf" ] || [ "$pm" == "yum" ]; then
        eval "$install_cmd httpd"
    else
        eval "$install_cmd apache2"
    fi
fi

# Configure Apache to allow .htaccess overrides
echo "Configuring Apache..."
if [ -f "$apache_conf" ]; then
    if [ "$pm" == "apt-get" ]; then
        sudo sed -i '/<\/VirtualHost>/i \
<Directory /var/www/html>\
    AllowOverride All\
</Directory>' "$apache_conf"
    else
        sudo sed -i '/<\/Directory>/i \
<Directory "/var/www/html">\
    AllowOverride All\
</Directory>' "$apache_conf"
    fi
else
    echo "[X] ERROR: Apache configuration file $apache_conf not found."
    exit 1
fi

# Enable mod_rewrite (Debian/Ubuntu only)
if [ "$pm" == "apt-get" ]; then
    echo "Enabling mod_rewrite..."
    sudo a2enmod rewrite
fi

# Restart Apache and verify it is running
echo "Restarting Apache..."
sudo systemctl restart "$apache_service"
check_service_running "$apache_service"

# Install PHP and required extensions
echo "Installing PHP and required modules..."
if [ "$pm" == "apt-get" ]; then
    eval "$install_cmd php libapache2-mod-php php-mysql php-curl php-gd php-dom php-xml php-cli php-common php-mbstring php-intl php-zip php-xmlrpc"
else
    eval "$install_cmd php php-mysqlnd php-curl php-gd php-xml php-cli php-mbstring"
fi

# Restart Apache again to load PHP modules and verify
echo "Restarting Apache to load PHP modules..."
sudo systemctl restart "$apache_service"
check_service_running "$apache_service"
check_php_version

# Verify required PHP modules are available
required_modules=("curl" "gd" "xml" "mbstring" "intl" "zip")
for mod in "${required_modules[@]}"; do
    check_php_module "$mod"
done

# Install MariaDB server
echo "Installing MariaDB server..."
if [ "$pm" == "apt-get" ]; then
    eval "$install_cmd mariadb-server"
else
    eval "$install_cmd mariadb-server"
fi

# Ensure MariaDB/MySQL service is running (service name may differ)
if systemctl is-active --quiet mariadb; then
    check_service_running "mariadb"
elif systemctl is-active --quiet mysql; then
    check_service_running "mysql"
else
    echo "[X] ERROR: Neither MariaDB nor MySQL service is running. Exiting."
    exit 1
fi

# Secure MariaDB installation (optional)
# Uncomment the following line if you wish to run the interactive secure installation:
# sudo mysql_secure_installation

echo "Creating the PrestaShop database and user..."
# Replace 'PASSWORD' below with a strong password of your choice
sudo mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS prestashop;
CREATE USER IF NOT EXISTS 'ps_user'@'localhost' IDENTIFIED BY 'PASSWORD';
GRANT ALL ON prestashop.* TO 'ps_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Change directory to the web root and download PrestaShop
echo "Downloading PrestaShop..."
WEB_ROOT="/var/www/html"
cd "$WEB_ROOT"
sudo wget -q https://assets.prestashop3.com/dst/edition/corporate/8.1.7/prestashop_edition_basic_version_8.1.7.zip -O prestashop.zip
if [ ! -f prestashop.zip ]; then
    echo "[X] ERROR: Failed to download the PrestaShop zip archive."
    exit 1
fi
echo "[*] PrestaShop archive downloaded successfully."

# Install unzip if not present and extract the archive
eval "$install_cmd unzip"
sudo unzip -o prestashop.zip -d prestashop
if [ ! -d prestashop ]; then
    echo "[X] ERROR: PrestaShop folder was not extracted correctly."
    exit 1
fi

# Set correct ownership for the PrestaShop directory
echo "Setting correct ownership for the PrestaShop directory..."
sudo chown -R "$apache_user":"$apache_user" "$WEB_ROOT/prestashop"

# Optionally check the permission of a key file (e.g. prestashop/index.php)
if [ -f "$WEB_ROOT/prestashop/index.php" ]; then
    # Check that the file has permission 644 (adjust if needed)
    check_file_permission "$WEB_ROOT/prestashop/index.php" "644"
fi

echo "PrestaShop installation script completed successfully."
