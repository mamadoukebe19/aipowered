#!/bin/bash
##############################################################
#  EC2 First-Time Setup Script
#  Run this ONCE on your fresh Ubuntu EC2 instance.
#  Usage:  bash ec2-setup.sh
##############################################################

set -e  # Exit on any error

REPO_URL="https://github.com/mamadoukebe19/aipowered.git"   # ← replace
APP_DIR="/var/www/demo-app"

echo "=== [1/6] Updating system packages ==="
sudo apt update && sudo apt upgrade -y

echo "=== [2/6] Installing Git ==="
sudo apt install -y git

echo "=== [3/6] Installing Nginx ==="
sudo apt install -y nginx

echo "=== [4/6] Cloning the repository ==="
sudo mkdir -p "$APP_DIR"
sudo git clone "$REPO_URL" "$APP_DIR"
# Give the ubuntu user ownership so git pull works without sudo
sudo chown -R ubuntu:ubuntu "$APP_DIR"

echo "=== [5/6] Configuring Nginx ==="
sudo cp "$APP_DIR/nginx.conf" /etc/nginx/sites-available/demo-app
sudo ln -sf /etc/nginx/sites-available/demo-app /etc/nginx/sites-enabled/demo-app
# Remove the default Nginx page
sudo rm -f /etc/nginx/sites-enabled/default
# Test config and reload
sudo nginx -t && sudo systemctl reload nginx

echo "=== [6/6] Enabling Nginx to start on boot ==="
sudo systemctl enable nginx

echo ""
echo "✅ Setup complete! Your app is live at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
