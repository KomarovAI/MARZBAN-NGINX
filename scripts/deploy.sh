#!/bin/bash

# Complete deployment script for Marzban + Nginx + Certbot
# Usage: ./deploy.sh

set -e

echo "🚀 Starting Marzban + Nginx + Certbot deployment..."
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Check if Docker and Docker Compose are installed
print_header "Checking prerequisites"

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_status "Docker and Docker Compose are installed"

# Load environment variables
if [ ! -f .env ]; then
    print_error ".env file not found. Please create .env file first."
    exit 1
fi

source .env
print_status "Environment variables loaded"

# Validate required environment variables
print_header "Validating configuration"

required_vars=("DOMAIN" "SSL_EMAIL" "SUDO_USERNAME" "SUDO_PASSWORD" "MYSQL_ROOT_PASSWORD" "MYSQL_PASSWORD")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        print_error "Required environment variable $var is not set in .env file"
        exit 1
    fi
done

print_status "All required environment variables are set"
print_status "Domain: $DOMAIN"
print_status "Email: $SSL_EMAIL"
print_status "Marzban Username: $SUDO_USERNAME"

# Create necessary directories
print_header "Creating directories"
mkdir -p certbot/conf certbot/www
mkdir -p /var/lib/marzban/mysql
chmod 755 /var/lib/marzban
print_status "Directories created"

# Stop any existing containers
print_header "Stopping existing containers"
docker compose down --remove-orphans || true
print_status "Existing containers stopped"

# Pull latest images
print_header "Pulling Docker images"
docker compose pull
print_status "Images pulled"

# Start MySQL first
print_header "Starting MySQL database"
docker compose up -d mysql
print_status "MySQL container started"

# Wait for MySQL to be ready
print_status "Waiting for MySQL to initialize..."
sleep 30

# Check MySQL connection
max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
    if docker compose exec mysql mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "SELECT 1" &>/dev/null; then
        print_status "MySQL is ready"
        break
    else
        print_status "MySQL not ready yet (attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    fi
done

if [ $attempt -gt $max_attempts ]; then
    print_error "MySQL failed to start properly"
    exit 1
fi

# Start Marzban
print_header "Starting Marzban"
docker compose up -d marzban
print_status "Marzban container started"

# Wait for Marzban to be ready
print_status "Waiting for Marzban to initialize..."
sleep 20

# Initialize SSL certificates
print_header "Initializing SSL certificates"
print_warning "This will request real SSL certificates from Let's Encrypt"
print_warning "Make sure your domain $DOMAIN points to this server's IP"

read -p "Continue with SSL certificate generation? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    chmod +x scripts/init-ssl.sh
    ./scripts/init-ssl.sh
else
    print_warning "Skipping SSL initialization. You can run ./scripts/init-ssl.sh later"
fi

# Generate VLESS Reality keys
print_header "Generating VLESS Reality keys"
chmod +x scripts/generate-keys.sh
./scripts/generate-keys.sh

# Final status check
print_header "Deployment status"

# Check container status
print_status "Container status:"
docker compose ps

# Test services
print_status "Testing service connectivity..."

# Test MySQL
if docker compose exec mysql mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "SELECT 1" &>/dev/null; then
    print_status "✅ MySQL: OK"
else
    print_error "❌ MySQL: Failed"
fi

# Test Marzban
if curl -f -s http://localhost:8000/docs &>/dev/null; then
    print_status "✅ Marzban: OK"
else
    print_warning "⚠️ Marzban: May not be fully ready yet"
fi

# Test Nginx
if curl -f -s http://localhost &>/dev/null; then
    print_status "✅ Nginx: OK"
else
    print_warning "⚠️ Nginx: May not be fully ready yet"
fi

print_header "Deployment completed!"

echo -e "\n${GREEN}=== ACCESS INFORMATION ===${NC}"
echo -e "${BLUE}Marzban Panel:${NC} https://$DOMAIN:8080"
echo -e "${BLUE}Username:${NC} $SUDO_USERNAME"
echo -e "${BLUE}Password:${NC} $SUDO_PASSWORD"
echo ""
echo -e "${BLUE}VLESS Reality Ports:${NC}"
echo "  - 2053 (Google Reality)"
echo "  - 2083 (Microsoft Reality)"
echo "  - 2087 (Cloudflare Reality)"
echo ""
echo -e "${GREEN}=== NEXT STEPS ===${NC}"
echo "1. Access the Marzban panel at https://$DOMAIN:8080"
echo "2. Create users in the panel"
echo "3. Use the VLESS Reality configuration from vless_client_config.json"
echo "4. Replace 'USER_UUID_HERE' in client config with actual user UUIDs"
echo ""
echo -e "${GREEN}=== USEFUL COMMANDS ===${NC}"
echo "View logs: docker compose logs -f"
echo "Restart services: docker compose restart"
echo "Update images: docker compose pull && docker compose up -d"
echo "Stop all: docker compose down"
echo ""
print_status "Deployment script completed successfully!"

# Save deployment info
cat > deployment_info.txt << EOF
Marzban + Nginx + Certbot Deployment
Deployed on: $(date)
Domain: $DOMAIN
Marzban Panel: https://$DOMAIN:8080
Username: $SUDO_USERNAME

VLESS Reality Ports:
- 2053 (Google Reality)
- 2083 (Microsoft Reality) 
- 2087 (Cloudflare Reality)

Client configuration template: vless_client_config.json
EOF

print_status "Deployment information saved to deployment_info.txt"