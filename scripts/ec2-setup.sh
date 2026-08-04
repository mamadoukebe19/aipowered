#!/bin/bash
##############################################################
#  EC2 First-Time Setup Script  (Apache version)
#  Run this ONCE on your fresh Ubuntu EC2 instance.
#  Usage:  bash ec2-setup.sh
##############################################################

set -e  # Exit on any error

REPO_URL="https://github.com/mamadoukebe19/aipowered.git"
APP_DIR="/var/www/html"   # Apache default web root

echo "=== [1/6] Updating system packages ==="
sudo apt update && sudo apt upgrade -y

echo "=== [2/6] Installing Git ==="
sudo apt install -y git

echo "=== [3/6] Removing Nginx (if present) and installing Apache ==="
sudo systemctl stop nginx 2>/dev/null || true
sudo apt remove -y nginx nginx-common 2>/dev/null || true
sudo apt install -y apache2

echo "=== [4/6] Cloning the repository into Apache web root ==="
# Remove the default Apache index page first
sudo rm -rf "$APP_DIR"
sudo git clone "$REPO_URL" "$APP_DIR"
# Give the ubuntu user ownership so git pull works without sudo later
sudo chown -R ubuntu:ubuntu "$APP_DIR"

echo "=== [5/6] Enabling mod_rewrite and restarting Apache ==="
sudo a2enmod rewrite
sudo systemctl restart apache2

echo "=== [6/6] Enabling Apache to start on boot ==="
sudo systemctl enable apache2

echo ""
echo "✅ Setup complete! Your app is live at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
