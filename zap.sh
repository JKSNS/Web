#!/bin/bash

# Script to install OWASP ZAP on a Linux system with openjdk-17-jdk

# Exit on any error
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Update package list and install openjdk-17-jdk
echo "Updating package list and installing openjdk-17-jdk..."
if ! command_exists java; then
    sudo apt update
    sudo apt install -y openjdk-17-jdk
else
    echo "Java is already installed. Version:"
    java -version
fi

# Verify Java installation
if ! java -version 2>&1 | grep -q "17"; then
    echo "Error: Java 17 is not installed correctly."
    exit 1
fi

# Step 2: Download OWASP ZAP Linux installer (version 2.16.1)
ZAP_VERSION="2.16.1"
ZAP_INSTALLER="ZAP_${ZAP_VERSION}_unix.sh"
ZAP_URL="https://github.com/zaproxy/zaproxy/releases/download/v${ZAP_VERSION}/${ZAP_INSTALLER}"

echo "Downloading OWASP ZAP ${ZAP_VERSION} installer..."
if ! wget -O "$ZAP_INSTALLER" "$ZAP_URL"; then
    echo "Error: Failed to download ZAP installer."
    exit 1
fi

# Step 3: Move to ~/Documents
echo "Changing to ~/Documents directory..."
cd ~/Documents || { echo "Error: Could not change to ~/Documents"; exit 1; }

# Step 4: Move the installer to ~/Documents (in case wget saved it elsewhere)
if [ ! -f "$ZAP_INSTALLER" ]; then
    mv ~/"$ZAP_INSTALLER" .
fi

# Step 5: Make the installer executable
echo "Making ${ZAP_INSTALLER} executable..."
chmod +x "$ZAP_INSTALLER"

# Step 6: Run the ZAP installer
echo "Running OWASP ZAP installer..."
echo "Note: The installer may prompt for user input (e.g., installation path, license agreement)."
./"$ZAP_INSTALLER"

# Step 7: Clean up
echo "Cleaning up..."
rm -f "$ZAP_INSTALLER"

echo "OWASP ZAP installation completed successfully!"
echo "You can start ZAP by running 'zaproxy' or from the installed directory (default: ~/ZAP_${ZAP_VERSION})."

exit 0
