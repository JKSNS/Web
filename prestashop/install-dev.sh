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
        apache_service="apache2"
        web_user="www-data"
        web_root="/var/www/html"
    elif command -v dnf &> /dev/null; then
        echo "[*] dnf detected (Fedora-based OS)"
        pm="dnf"
        update_cmd="sudo dnf update -y"
        install_cmd="sudo dnf install -y"
        apache_service="httpd"
        web_user="apache"
        web_root="/var/www/html"
    elif command -v zypper &> /dev/null; then
        echo "[*] zypper detected (OpenSUSE-based OS)"
        pm="zypper"
        update_cmd="sudo zypper refresh"
        install_cmd="sudo zypper install -y"
        apache_service="apache2"
        web_user="www-data"
        web_root="/var/www/html"
    elif command -v yum &> /dev/null; then
        echo "[*] yum detected (RHEL-based OS)"
        pm="yum"
        update_cmd="sudo yum update -y"
        install_cmd="sudo yum install -y"
        apache_service="httpd"
        web_user="apache"
        web_root="/var/www/html"
    else
        echo "[X] ERROR: Could not detect package manager"
        exit 1
    fi

    echo "[*] Using package manager: $pm"
}

function install_web_app {
    # Detect system info
    detect_system_info

    # Update and upgrade system packages
    echo "Updating system..."
    eval "$update_cmd"

    # Install Apache
    echo "Installing Apache..."
    eval "$install_cmd $apache_service"

    # Configure Apache to allow .htaccess overrides
    echo "Configuring Apache..."
    if [ "$pm" == "apt-get" ]; then
        APACHE_CONF="/etc/apache2/sites-available/000-default.conf"
        sudo sed -i '/<\/VirtualHost>/i \
<Directory /var/www/html>\
    AllowOverride All\
</Directory>' "$APACHE_CONF"
    else
        APACHE_CONF="/etc/$apache_service/conf/httpd.conf"
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
    sudo systemctl restart "$apache_service"

    # Install PHP and required extensions
    echo "Installing PHP and required modules..."
    if [ "$pm" == "apt-get" ]; then
        eval "$install_cmd php libapache2-mod-php php-mysql php-curl php-gd php-dom php-xml php-cli php-common php-mbstring php-intl php-zip php-xmlrpc"
    else
        eval "$install_cmd php php-mysqlnd php-curl php-gd php-xml php-cli php-mbstring"
    fi

    # Restart Apache to load PHP modules
    sudo systemctl restart "$apache_service"

    # Install MariaDB server
    echo "Installing MariaDB server..."
    eval "$install_cmd mariadb-server"

    # Enable & start MariaDB, then verify it's running
    echo "Starting MariaDB service..."
    sudo systemctl enable mariadb
    sudo systemctl start mariadb

    if ! systemctl is-active --quiet mariadb; then
        echo "[X] MariaDB service failed to start. Check logs with: sudo journalctl -xeu mariadb"
        exit 1
    fi

    # Create PrestaShop database and user gracefully
    echo "Creating the PrestaShop database and user..."
    DB_NAME="prestashop"
    DB_USER="ps_user"
    DB_PASS="PASSWORD" # ← replace with a strong password

    # Check if database exists
    if sudo mysql -u root -e "use $DB_NAME" 2>/dev/null; then
        echo "[*] Database $DB_NAME already exists, continuing..."
    else
        sudo mysql -u root -e "CREATE DATABASE $DB_NAME;"
    fi

    # Check if user exists
    if sudo mysql -u root -e "SELECT 1 FROM mysql.user WHERE user = '$DB_USER' AND host = 'localhost'" | grep -q 1; then
        echo "[*] User $DB_USER already exists, continuing..."
    else
        sudo mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    fi

    # Grant privileges
    sudo mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"

    # Download and extract PrestaShop
    echo "Downloading PrestaShop..."
    cd "$web_root"
    if [ -d "prestashop" ]; then
        echo "[*] Directory $web_root/prestashop already exists, skipping download..."
    else
        sudo wget https://assets.prestashop3.com/dst/edition/corporate/8.1.7/prestashop_edition_basic_version_8.1.7.zip
        eval "$install_cmd unzip"
        sudo unzip prestashop_edition_basic_version_8.1.7.zip -d prestashop
    fi

    # Set correct ownership
    sudo chown -R "$web_user":"$web_user" "$web_root/prestashop"

    echo "PrestaShop installation completed successfully."
}

function uninstall_web_app {
    echo "Uninstalling PrestaShop and related components..."

    # Detect system info
    detect_system_info

    # Remove PrestaShop files
    echo "Removing PrestaShop files..."
    if [ -d "$web_root/prestashop" ]; then
        sudo rm -rf "$web_root/prestashop"
        echo "[*] PrestaShop files removed."
    else
        echo "[*] PrestaShop directory not found, skipping..."
    fi

    # Remove PrestaShop database and user
    echo "Removing PrestaShop database and user..."
    DB_NAME="prestashop"
    DB_USER="ps_user"
    sudo mysql -u root -e "DROP DATABASE IF EXISTS $DB_NAME;"
    sudo mysql -u root -e "DROP USER IF EXISTS '$DB_USER'@'localhost';"
    sudo mysql -u root -e "FLUSH PRIVILEGES;"
    echo "[*] PrestaShop database and user removed."

    # Clean up downloaded zip file
    if [ -f "$web_root/prestashop_edition_basic_version_8.1.7.zip" ]; then
        sudo rm "$web_root/prestashop_edition_basic_version_8.1.7.zip"
        echo "[*] PrestaShop zip file removed."
    fi

    echo "Uninstallation completed successfully."
}

function display_menu {
    echo "================================="
    echo "PrestaShop Installation Script"
    echo "================================="
    echo "1. Install web app"
    echo "2. Uninstall web app"
    echo "3. Exit script"
    echo "================================="
    read -p "Please select an option [1-3]: " choice
    case $choice in
        1) install_web_app ;;
        2) uninstall_web_app ;;
        3) echo "Exiting script..."; exit 0 ;;
        *) echo "[X] Invalid option, please try again."; display_menu ;;
    esac
}

# Kick off
display_menu
