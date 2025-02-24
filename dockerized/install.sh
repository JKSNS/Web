#!/bin/bash

#############################
# Helper: Print Banner
#############################
function print_banner() {
    echo "===================================="
    echo "$1"
    echo "===================================="
}

#############################
# Detect System Information
#############################
function detect_system_info {
    print_banner "Detecting system info"
    echo "[*] Detecting package manager"

    sudo which apt-get &> /dev/null
    apt=$?
    sudo which dnf &> /dev/null
    dnf=$?
    sudo which zypper &> /dev/null
    zypper=$?
    sudo which yum &> /dev/null
    yum=$?

    if [ $apt == 0 ]; then
        echo "[*] apt/apt-get detected (Debian-based OS)"
        echo "[*] Updating package list"
        sudo apt-get update
        pm="apt-get"
    elif [ $dnf == 0 ]; then
        echo "[*] dnf detected (Fedora-based OS)"
        pm="dnf"
    elif [ $zypper == 0 ]; then
        echo "[*] zypper detected (OpenSUSE-based OS)"
        pm="zypper"
    elif [ $yum == 0 ]; then
        echo "[*] yum detected (RHEL-based OS)"
        pm="yum"
    else
        echo "[X] ERROR: Could not detect package manager"
        exit 1
    fi

    echo "[*] Detecting sudo group"
    groups=$(compgen -g)
    if echo "$groups" | grep -q '^sudo$'; then
        echo '[*] sudo group detected'
        sudo_group='sudo'
    elif echo "$groups" | grep -q '^wheel$'; then
        echo '[*] wheel group detected'
        sudo_group='wheel'
    else
        echo '[X] ERROR: could not detect sudo group'
        exit 1
    fi
}

#############################
# Install Prerequisites
#############################
function install_prerequisites {
    print_banner "Installing prerequisites"
    case "$pm" in
        apt-get)
            sudo apt-get install -y git net-tools docker.io docker-compose
            ;;
        dnf)
            sudo dnf install -y git net-tools docker docker-compose
            ;;
        yum)
            sudo yum install -y git net-tools docker docker-compose
            ;;
        zypper)
            sudo zypper install -y git net-tools docker docker-compose
            ;;
        *)
            echo "[X] ERROR: Unknown package manager"
            exit 1
            ;;
    esac
    echo "[*] Enabling and starting Docker service"
    sudo systemctl enable docker
    sudo systemctl start docker
}

#############################
# Container Operations
#############################

# Install container(s)
function install_container {
    print_banner "Installing container: $1"
    case "$1" in
        prestashop)
            # Create docker network if not exists
            docker network ls | grep -q prestashop-net || docker network create prestashop-net
            # Launch MySQL container for PrestaShop
            docker run -ti --name some-mysql --network prestashop-net -e MYSQL_ROOT_PASSWORD=admin -p 3307:3306 -d mysql:5.7
            # Launch PrestaShop container
            docker run -ti --name some-prestashop --network prestashop-net -e DB_SERVER=some-mysql -p 8080:80 -d prestashop/prestashop:latest
            echo "[*] PrestaShop containers installed. Access your shop at http://localhost:8080"
            ;;
        opencart)
            echo "[*] Installation details for OpenCart are not provided yet."
            ;;
        zencart)
            echo "[*] Installation details for ZenCart are not provided yet."
            ;;
        wordpress)
            echo "[*] Installation details for WordPress are not provided yet."
            ;;
        drupal)
            echo "[*] Installation details for Drupal are not provided yet."
            ;;
        magento)
            echo "[*] Installation details for Magento are not provided yet."
            ;;
        laravel)
            echo "[*] Installation details for Laravel are not provided yet."
            ;;
        *)
            echo "[X] Unknown container: $1"
            ;;
    esac
}

# Start container(s)
function start_container {
    print_banner "Starting container: $1"
    case "$1" in
        prestashop)
            docker start some-mysql
            docker start some-prestashop
            echo "[*] PrestaShop containers started."
            ;;
        opencart)
            echo "[*] Start operation for OpenCart is not provided yet."
            ;;
        zencart)
            echo "[*] Start operation for ZenCart is not provided yet."
            ;;
        wordpress)
            echo "[*] Start operation for WordPress is not provided yet."
            ;;
        drupal)
            echo "[*] Start operation for Drupal is not provided yet."
            ;;
        magento)
            echo "[*] Start operation for Magento is not provided yet."
            ;;
        laravel)
            echo "[*] Start operation for Laravel is not provided yet."
            ;;
        *)
            echo "[X] Unknown container: $1"
            ;;
    esac
}

# Stop container(s)
function stop_container {
    print_banner "Stopping container: $1"
    case "$1" in
        prestashop)
            docker stop some-prestashop
            docker stop some-mysql
            echo "[*] PrestaShop containers stopped."
            ;;
        opencart)
            echo "[*] Stop operation for OpenCart is not provided yet."
            ;;
        zencart)
            echo "[*] Stop operation for ZenCart is not provided yet."
            ;;
        wordpress)
            echo "[*] Stop operation for WordPress is not provided yet."
            ;;
        drupal)
            echo "[*] Stop operation for Drupal is not provided yet."
            ;;
        magento)
            echo "[*] Stop operation for Magento is not provided yet."
            ;;
        laravel)
            echo "[*] Stop operation for Laravel is not provided yet."
            ;;
        *)
            echo "[X] Unknown container: $1"
            ;;
    esac
}

#############################
# Menu Functions
#############################
function display_menu {
    echo "============================"
    echo "Docker Open Source Websites"
    echo "============================"
    echo "1) Install container"
    echo "2) Start container"
    echo "3) Stop container"
    echo "4) Exit"
    echo "============================"
}

function select_container {
    echo "Available containers:"
    echo "1) prestashop"
    echo "2) opencart"
    echo "3) zencart"
    echo "4) wordpress"
    echo "5) drupal"
    echo "6) magento"
    echo "7) laravel"
    read -p "Select a container (1-7): " container_choice
    case $container_choice in
        1) container="prestashop" ;;
        2) container="opencart" ;;
        3) container="zencart" ;;
        4) container="wordpress" ;;
        5) container="drupal" ;;
        6) container="magento" ;;
        7) container="laravel" ;;
        *) echo "Invalid option"; container="" ;;
    esac
}

#############################
# Main Function
#############################
function main {
    detect_system_info
    install_prerequisites

    while true; do
        display_menu
        read -p "Select an option: " option
        case $option in
            1)
                select_container
                if [ -n "$container" ]; then
                    install_container "$container"
                fi
                ;;
            2)
                select_container
                if [ -n "$container" ]; then
                    start_container "$container"
                fi
                ;;
            3)
                select_container
                if [ -n "$container" ]; then
                    stop_container "$container"
                fi
                ;;
            4)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid option, please try again."
                ;;
        esac
    done
}

# Start the script
main
