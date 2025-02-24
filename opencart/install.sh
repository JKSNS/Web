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

# Install PHP and required modules
echo "Installing PHP and required modules..."
if [ "$pm" == "apt-get" ]; then
    eval "$install_cmd php libapache2-mod-php php-cli php-common php-mbstring php-gd php-intl php-xml php-mysql php-zip php-curl php-xmlrpc"
else
    # Package names for Fedora/RHEL might differ
    eval "$install_cmd php php-mysqlnd php-cli php-common php-mbstring php-gd php-intl php-xml php-zip php-curl"
fi

# Restart Apache to load PHP modules
if [ "$pm" == "apt-get" ]; then
    sudo systemctl restart apache2
else
    sudo systemctl restart httpd
fi

# Install MariaDB server and client
echo "Installing MariaDB server and client..."
if [ "$pm" == "apt-get" ]; then
    eval "$install_cmd mariadb-server mariadb-client"
else
    eval "$install_cmd mariadb-server mariadb"
fi

# (Optional) Secure MariaDB installation interactively.
# Uncomment the next line to run the interactive secure installation.
# sudo mysql_secure_installation

echo "Creating the OpenCart database and user..."
# Replace 'strong_password' with your desired strong password.
# If the root user does not have a password, remove the -p flag.
sudo mysql -u root <<EOF
CREATE DATABASE opencartdb;
CREATE USER 'opencart_user'@'localhost' IDENTIFIED BY 'strong_password';
GRANT ALL ON opencartdb.* TO 'opencart_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Download and install OpenCart
echo "Downloading OpenCart..."
cd /tmp
sudo wget https://github.com/opencart/opencart/releases/download/3.0.2.0/3.0.2.0-OpenCart.zip

echo "Unzipping OpenCart..."
sudo apt install unzip -y  # or use the install_cmd for your distro if not using apt
sudo unzip 3.0.2.0-OpenCart.zip

echo "Moving OpenCart files to web root..."
WEB_ROOT="/var/www/html"
sudo mv upload/ "$WEB_ROOT/opencart"

echo "Configuring OpenCart..."
# Copy configuration files
sudo cp "$WEB_ROOT/opencart/config-dist.php" "$WEB_ROOT/opencart/config.php"
sudo cp "$WEB_ROOT/opencart/admin/config-dist.php" "$WEB_ROOT/opencart/admin/config.php"

# Set proper permissions and ownership
sudo chmod -R 755 "$WEB_ROOT/opencart"
if [ "$pm" == "apt-get" ]; then
    sudo chown -R www-data:www-data "$WEB_ROOT/opencart"
else
    # On Fedora/RHEL systems Apache often runs as 'apache'
    sudo chown -R apache:apache "$WEB_ROOT/opencart"
fi

# Create Apache VirtualHost configuration for OpenCart
echo "Creating VirtualHost configuration for OpenCart..."
if [ "$pm" == "apt-get" ]; then
    VHOST_PATH="/etc/apache2/sites-available/opencart.conf"
else
    # For Fedora/RHEL systems, adjust path as necessary.
    VHOST_PATH="/etc/httpd/conf.d/opencart.conf"
fi

sudo bash -c "cat > $VHOST_PATH" <<EOF
<VirtualHost *:80>
    ServerName example.com
    DocumentRoot ${WEB_ROOT}/opencart/upload/

    <Directory ${WEB_ROOT}/opencart/upload/>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Enable the new VirtualHost and disable the default site if on Debian-based systems
if [ "$pm" == "apt-get" ]; then
    sudo a2ensite opencart.conf
    sudo a2dissite 000-default.conf
    sudo systemctl restart apache2
else
    # For Fedora/RHEL, restart Apache to pick up new configuration
    sudo systemctl restart httpd
fi

# Enable mod_rewrite for URL rewriting
echo "Enabling mod_rewrite..."
if [ "$pm" == "apt-get" ]; then
    sudo a2enmod rewrite
    sudo systemctl restart apache2
else
    # On systems like Fedora/RHEL, mod_rewrite is usually enabled by default.
    sudo systemctl restart httpd
fi

echo "OpenCart installation script completed successfully."
