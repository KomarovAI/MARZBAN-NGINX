#!/bin/bash

# Script to initialize SSL certificates for Marzban with Nginx
# Since port 80 is handled by external nginx, we use standalone mode
# Usage: ./init-ssl.sh

set -e

# Load environment variables
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Configuration
DOMAIN=${DOMAIN:-botinger789298.work.gd}
EMAIL=${SSL_EMAIL:-artur.komarovv@gmail.com}
RSA_KEY_SIZE=4096
DATA_PATH="./certbot"
STAGING=0  # Set to 1 for testing

echo "🚀 Initializing SSL certificates for domain: $DOMAIN"
echo "📧 Email: $EMAIL"
echo "⚠️  Using standalone mode since external nginx handles port 80"

# Create directories
echo "📁 Creating directories..."
mkdir -p "$DATA_PATH/conf" "$DATA_PATH/www"

# Check if certificates already exist
if [ -d "$DATA_PATH/conf/live/$DOMAIN" ]; then
  echo "⚠️  Existing data found for $DOMAIN"
  read -p "Continue and replace existing certificate? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted"
    exit 1
  fi
fi

# Download recommended TLS parameters
if [ ! -e "$DATA_PATH/conf/options-ssl-nginx.conf" ] || [ ! -e "$DATA_PATH/conf/ssl-dhparams.pem" ]; then
  echo "🔐 Downloading recommended TLS parameters..."
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$DATA_PATH/conf/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$DATA_PATH/conf/ssl-dhparams.pem"
  echo "✅ TLS parameters downloaded"
fi

# Create dummy certificate
echo "🔧 Creating dummy certificate for $DOMAIN..."
path="/etc/letsencrypt/live/$DOMAIN"
mkdir -p "$DATA_PATH/conf/live/$DOMAIN"
docker compose run --rm --entrypoint "\
  openssl req -x509 -nodes -newkey rsa:$RSA_KEY_SIZE -days 1\
    -keyout '$path/privkey.pem' \
    -out '$path/fullchain.pem' \
    -subj '/CN=localhost'" certbot
echo "✅ Dummy certificate created"

# Start nginx
echo "🚀 Starting nginx..."
docker compose up --force-recreate -d nginx
echo "✅ Nginx started"

# Wait for nginx to be ready
echo "⏳ Waiting for nginx to be ready..."
sleep 10

# Delete dummy certificate
echo "🗑️  Deleting dummy certificate..."
docker compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/$DOMAIN && \
  rm -Rf /etc/letsencrypt/archive/$DOMAIN && \
  rm -Rf /etc/letsencrypt/renewal/$DOMAIN.conf" certbot
echo "✅ Dummy certificate deleted"

# Stop nginx temporarily for standalone mode
echo "⏸️  Stopping nginx temporarily for certificate generation..."
docker compose stop nginx

# Request Let's Encrypt certificate using standalone mode
echo "🔒 Requesting Let's Encrypt certificate for $DOMAIN using standalone mode..."

# Prepare domain arguments
domain_args="-d $DOMAIN"

# Prepare email argument
if [ -z "$EMAIL" ]; then
  email_arg="--register-unsafely-without-email"
else
  email_arg="--email $EMAIL"
fi

# Prepare staging argument
if [ $STAGING != "0" ]; then
  staging_arg="--staging"
  echo "⚠️  Using staging environment (test certificates)"
else
  staging_arg=""
  echo "🌟 Using production environment (real certificates)"
fi

# Request certificate using standalone mode
docker compose run --rm --network host --entrypoint "\
  certbot certonly --standalone \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $RSA_KEY_SIZE \
    --agree-tos \
    --force-renewal \
    --non-interactive" certbot

echo "✅ Certificate requested successfully!"

# Start nginx again
echo "🚀 Starting nginx with SSL certificates..."
docker compose up -d nginx

echo "⏳ Waiting for nginx to start..."
sleep 5

# Reload nginx
echo "🔄 Reloading nginx..."
docker compose exec nginx nginx -s reload
echo "✅ Nginx reloaded"

echo "🎉 SSL initialization completed successfully!"
echo "🌐 Your Marzban panel should now be available at:"
echo "   - https://$DOMAIN:8080 (Panel)"
echo "   - VLESS Reality ports: 2053, 2083, 2087"
echo ""
echo "📝 Important Notes:"
echo "   - External nginx on port 80 should handle your website"
echo "   - SSL certificate renewal will use standalone mode"
echo "   - Make sure to stop external nginx temporarily during renewal"
echo ""
echo "🔐 Don't forget to run the key generation script: ./generate-keys.sh"