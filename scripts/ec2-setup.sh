#!/bin/bash

set -e

REPO_URL="https://github.com/mamadoukebe19/aipowered.git"
APP_DIR="/var/www/html"

echo "=== Installing Apache and Git ==="

sudo apt update -y
sudo apt install -y apache2 git

echo "=== Removing default Apache page ==="

sudo rm -rf "$APP_DIR"/*

echo "=== Cloning application ==="

sudo git clone "$REPO_URL" "$APP_DIR"

echo "=== Setting permissions ==="

sudo chown -R www-data:www-data "$APP_DIR"
sudo chmod -R 755 "$APP_DIR"

echo "=== Starting Apache ==="

sudo systemctl enable apache2
sudo systemctl restart apache2

echo "=== Testing Apache ==="

curl -I http://localhost

echo ""
echo "======================================"
echo "Installation completed"
echo "======================================"

echo "Application files:"
ls -lah "$APP_DIR"
