#!/bin/sh

set -e

# Prompt for domain names
echo "Enter your first domain name (for port 3000): "
read DOMAIN_NAME

# Enable EPEL and CodeReady Builder repositories
echo "Enabling EPEL and CodeReady Builder repositories..."
sudo dnf install -y epel-release
sudo dnf config-manager --set-enabled crb

# Install required packages including certbot
echo "Installing required packages..."
sudo dnf install -y curl git nano nginx certbot python3-certbot-nginx

# Install Docker using official Docker repo
echo "Installing Docker..."
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker

# Clone the WhatsApp API repository
echo "Cloning the WhatsApp API repository..."
if [ ! -d "whatsapp-api" ]; then
    git clone https://github.com/chrishubert/whatsapp-api.git
fi
cd whatsapp-api || exit 1

# Configure Nginx
echo "Configuring Nginx..."
sudo mkdir -p /etc/nginx/conf.d
sudo rm -f /etc/nginx/default.d/*

# First domain config
sudo sh -c "cat > /etc/nginx/conf.d/whatssy-server.conf <<EOL
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection upgrade;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL
"

# Test and restart Nginx
echo "Testing Nginx configuration..."
sudo nginx -t
echo "Restarting Nginx..."
sudo systemctl enable --now nginx

# Obtain SSL certificates using certbot
echo "Obtaining SSL certificates using Certbot..."
sudo certbot --nginx -d "$DOMAIN_NAME"

# Final output
echo "Setup complete for both domains:"
echo " - https://$DOMAIN_NAME -> 127.0.0.1:3000"