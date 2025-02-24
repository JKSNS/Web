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
        apache_pkg="apache2"
        php_pkg="php"
        mysql_pkg="mysql-server"
    elif command -v dnf &> /dev/null; then
        echo "[*] dnf detected (Fedora-based OS)"
        pm="dnf"
        update_cmd="sudo dnf update -y"
        install_cmd="sudo dnf install -y"
        apache_service="httpd"
        apache_pkg="httpd"
        php_pkg="php"
        mysql_pkg="mariadb-server"
    elif command -v zypper &> /dev/null; then
        echo "[*] zypper detected (OpenSUSE-based OS)"
        pm="zypper"
        update_cmd="sudo zypper refresh"
        install_cmd="sudo zypper install -y"
        apache_service="apache2"
        apache_pkg="apache2"
        php_pkg="php7"
        mysql_pkg="mariadb"
    elif command -v yum &> /dev/null; then
        echo "[*] yum detected (RHEL-based OS)"
        pm="yum"
        update_cmd="sudo yum update -y"
        install_cmd="sudo yum install -y"
        apache_service="httpd"
        apache_pkg="httpd"
        php_pkg="php"
        mysql_pkg="mariadb-server"
    else
        echo "[X] ERROR: Could not detect package manager"
        exit 1
    fi

    echo "[*] Using package manager: $pm"
}

# Detect system info and set package manager variables
detect_system_info

# Update and upgrade system packages
echo "Updating system..."
eval "$update_cmd"

# Install Apache, PHP and required PHP extensions, and MySQL/MariaDB
echo "Installing Apache, PHP, and MySQL/MariaDB..."
if [ "$pm" == "apt-get" ]; then
    eval "$install_cmd $apache_pkg ghostscript libapache2-mod-php $mysql_pkg $php_pkg php-bcmath php-curl php-imagick php-intl php-json php-mbstring php-mysql php-xml php-zip"
else
    # Adjust package names if necessary for non-Debian distros.
    eval "$install_cmd $apache_pkg $mysql_pkg $php_pkg php-bcmath php-curl php-imagick php-intl php-json php-mbstring php-mysql php-xml php-zip"
fi

# Start and enable services
echo "Starting services..."
if [ "$pm" == "apt-get" ]; then
    sudo systemctl restart apache2
    sudo systemctl restart mysql
else
    sudo systemctl restart $apache_service
    sudo systemctl restart mariadb || sudo systemctl restart mysql
fi

# Create Apache virtual host configuration for WordPress
echo "Configuring Apache for WordPress..."
if [ "$pm" == "apt-get" ]; then
    APACHE_CONF="/etc/apache2/sites-available/wordpress.conf"
else
    # On Fedora/RHEL, configuration may be in /etc/httpd/conf.d
    APACHE_CONF="/etc/httpd/conf.d/wordpress.conf"
fi

sudo tee "$APACHE_CONF" > /dev/null <<EOF
<VirtualHost *:80>
    DocumentRoot /srv/www/wordpress
    <Directory /srv/www/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory /srv/www/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Enable the WordPress site and URL rewriting (for Debian-based systems)
if [ "$pm" == "apt-get" ]; then
    sudo a2ensite wordpress
    sudo a2enmod rewrite
    sudo a2dissite 000-default
fi

# Reload Apache to apply changes
echo "Reloading Apache..."
sudo systemctl reload $apache_service

# Create WordPress database and user
echo "Creating the WordPress database and user..."
# Replace <your-password> with a strong password
sudo mysql -u root <<EOF
CREATE DATABASE wordpress;
CREATE USER 'wordpress'@'localhost' IDENTIFIED BY '<your-password>';
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER ON wordpress.* TO 'wordpress'@'localhost';
FLUSH PRIVILEGES;
EOF

# Create web root and download WordPress
echo "Downloading WordPress..."
WEB_ROOT="/srv/www"
sudo mkdir -p "$WEB_ROOT"
# Ensure correct ownership – note: running as www-data may be insecure for multi-site setups.
if [ "$pm" == "apt-get" ]; then
    sudo chown www-data: "$WEB_ROOT"
else
    # Adjust ownership for non-Debian systems; typically 'apache'
    sudo chown apache: "$WEB_ROOT"
fi

# Download and extract WordPress
curl -s https://wordpress.org/latest.tar.gz | sudo -u $( [ "$pm" == "apt-get" ] && echo "www-data" || echo "apache" ) tar zx -C "$WEB_ROOT"

# Configure WordPress to connect to the database
echo "Configuring WordPress..."
WP_CONFIG="$WEB_ROOT/wordpress/wp-config.php"
sudo -u $( [ "$pm" == "apt-get" ] && echo "www-data" || echo "apache" ) cp "$WEB_ROOT/wordpress/wp-config-sample.php" "$WP_CONFIG"
sudo -u $( [ "$pm" == "apt-get" ] && echo "www-data" || echo "apache" ) sed -i 's/database_name_here/wordpress/' "$WP_CONFIG"
sudo -u $( [ "$pm" == "apt-get" ] && echo "www-data" || echo "apache" ) sed -i 's/username_here/wordpress/' "$WP_CONFIG"
sudo -u $( [ "$pm" == "apt-get" ] && echo "www-data" || echo "apache" ) sed -i 's/password_here/<your-password>/' "$WP_CONFIG"

# Fetch fresh WordPress secret keys and append them to wp-config.php
echo "Fetching fresh secret keys..."
sudo -u $( [ "$pm" == "apt-get" ] && echo "www-data" || echo "apache" ) bash -c 'curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> "'"$WP_CONFIG"'"'

echo "WordPress installation script completed successfully."
