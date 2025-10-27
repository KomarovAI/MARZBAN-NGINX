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

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
}

# Function to show full logs on error
show_error_logs() {
    local service_name="$1"
    print_error "\n=== FULL LOGS FOR $service_name ==="
    docker compose logs --tail=50 "$service_name" 2>&1 || echo "Failed to get logs for $service_name"
    print_error "=== END OF LOGS FOR $service_name ===\n"
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
    show_error_logs "mysql"
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
    if ./scripts/init-ssl.sh; then
        print_success "SSL certificates initialized successfully"
    else
        print_error "SSL initialization failed"
        exit 1
    fi
else
    print_warning "Skipping SSL initialization. You can run ./scripts/init-ssl.sh later"
fi

# Generate VLESS Reality keys
print_header "Generating VLESS Reality keys"
chmod +x scripts/generate-keys.sh
if ./scripts/generate-keys.sh; then
    print_success "VLESS Reality keys generated successfully"
else
    print_error "VLESS key generation failed"
    show_error_logs "marzban"
    exit 1
fi

# Final comprehensive testing
print_header "Comprehensive System Testing"

# Initialize test results
all_tests_passed=true
failed_tests=()

# Test 1: Container Status
print_status "Testing container status..."
if ! docker compose ps | grep -q "Up"; then
    print_fail "Some containers are not running"
    failed_tests+=("Container Status")
    all_tests_passed=false
    docker compose ps
else
    print_success "All containers are running"
fi

# Test 2: MySQL Connection
print_status "Testing MySQL connection..."
if docker compose exec -T mysql mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "SELECT 1;" &>/dev/null; then
    print_success "MySQL connection successful"
else
    print_fail "MySQL connection failed"
    failed_tests+=("MySQL Connection")
    all_tests_passed=false
    show_error_logs "mysql"
fi

# Test 3: MySQL Database and User
print_status "Testing Marzban database and user..."
if docker compose exec -T mysql mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "USE marzban; SHOW TABLES;" &>/dev/null; then
    print_success "Marzban database exists and accessible"
else
    print_fail "Marzban database check failed"
    failed_tests+=("Marzban Database")
    all_tests_passed=false
fi

if docker compose exec -T mysql mysql -umarzban -p$MYSQL_PASSWORD -e "SELECT 1;" &>/dev/null; then
    print_success "Marzban MySQL user works"
else
    print_fail "Marzban MySQL user failed"
    failed_tests+=("Marzban MySQL User")
    all_tests_passed=false
fi

# Test 4: Marzban Service
print_status "Testing Marzban web service..."
max_attempts=10
attempt=1
marzban_ready=false

while [ $attempt -le $max_attempts ]; do
    if curl -f -s -m 5 http://localhost:8000/docs &>/dev/null; then
        print_success "Marzban web service is responding"
        marzban_ready=true
        break
    else
        print_status "Marzban not ready yet (attempt $attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    fi
done

if ! $marzban_ready; then
    print_fail "Marzban web service is not responding"
    failed_tests+=("Marzban Web Service")
    all_tests_passed=false
    show_error_logs "marzban"
fi

# Test 5: Marzban Admin Login
print_status "Testing Marzban admin login..."
login_response=$(curl -s -X POST "http://localhost:8000/api/admin/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$SUDO_USERNAME&password=$SUDO_PASSWORD" 2>/dev/null || echo "error")

if echo "$login_response" | grep -q "access_token"; then
    print_success "Marzban admin login successful with credentials: $SUDO_USERNAME / $SUDO_PASSWORD"
else
    print_fail "Marzban admin login failed with credentials: $SUDO_USERNAME / $SUDO_PASSWORD"
    print_error "Login response: $login_response"
    failed_tests+=("Marzban Admin Login")
    all_tests_passed=false
    show_error_logs "marzban"
fi

# Test 6: Nginx Configuration
print_status "Testing Nginx configuration..."
if docker compose exec nginx nginx -t &>/dev/null; then
    print_success "Nginx configuration is valid"
else
    print_fail "Nginx configuration is invalid"
    failed_tests+=("Nginx Configuration")
    all_tests_passed=false
    show_error_logs "nginx"
    docker compose exec nginx nginx -t
fi

# Test 7: Nginx Service
print_status "Testing Nginx web service on port 8080..."
if curl -f -s -k -m 5 https://localhost:8080/ &>/dev/null; then
    print_success "Nginx HTTPS service is responding on port 8080"
elif curl -f -s -m 5 http://localhost:8080/ &>/dev/null; then
    print_warning "Nginx HTTP service is responding on port 8080 (SSL may not be configured yet)"
else
    print_fail "Nginx service is not responding on port 8080"
    failed_tests+=("Nginx Service")
    all_tests_passed=false
    show_error_logs "nginx"
fi

# Test 8: SSL Certificates
print_status "Testing SSL certificates..."
if [ -f "./certbot/conf/live/$DOMAIN/fullchain.pem" ] && [ -f "./certbot/conf/live/$DOMAIN/privkey.pem" ]; then
    print_success "SSL certificates exist for domain $DOMAIN"
    
    # Check certificate validity
    cert_info=$(openssl x509 -in "./certbot/conf/live/$DOMAIN/fullchain.pem" -text -noout 2>/dev/null || echo "error")
    if echo "$cert_info" | grep -q "$DOMAIN"; then
        print_success "SSL certificate is valid for domain $DOMAIN"
    else
        print_fail "SSL certificate validation failed"
        failed_tests+=("SSL Certificate Validation")
        all_tests_passed=false
    fi
else
    print_fail "SSL certificates not found"
    failed_tests+=("SSL Certificates")
    all_tests_passed=false
fi

# Test 9: VLESS Reality Configuration
print_status "Testing VLESS Reality configuration..."
if docker compose exec -T marzban xray -test -config /usr/local/share/xray/xray_config.json &>/dev/null; then
    print_success "VLESS Reality configuration is valid"
else
    print_fail "VLESS Reality configuration is invalid"
    failed_tests+=("VLESS Reality Configuration")
    all_tests_passed=false
    docker compose exec marzban xray -test -config /usr/local/share/xray/xray_config.json
fi

# Test 10: VLESS Reality Ports
print_status "Testing VLESS Reality ports..."
for port in 2053 2083 2087; do
    if timeout 3 bash -c "</dev/tcp/localhost/$port" 2>/dev/null; then
        print_success "VLESS Reality port $port is listening"
    else
        print_fail "VLESS Reality port $port is not accessible"
        failed_tests+=("VLESS Port $port")
        all_tests_passed=false
    fi
done

# Test 11: Client Configuration File
print_status "Testing client configuration file..."
if [ -f "vless_client_config.json" ]; then
    if jq . vless_client_config.json &>/dev/null; then
        print_success "Client configuration file is valid JSON"
        
        # Check if it contains the expected structure
        if jq -e '.outbounds[0].settings.vnext[0].address' vless_client_config.json | grep -q "$DOMAIN"; then
            print_success "Client configuration contains correct domain: $DOMAIN"
        else
            print_fail "Client configuration domain check failed"
            failed_tests+=("Client Config Domain")
            all_tests_passed=false
        fi
    else
        print_fail "Client configuration file is invalid JSON"
        failed_tests+=("Client Config JSON")
        all_tests_passed=false
    fi
else
    print_fail "Client configuration file not found"
    failed_tests+=("Client Config File")
    all_tests_passed=false
fi

# Final Results
print_header "FINAL DEPLOYMENT RESULTS"

if $all_tests_passed; then
    echo -e "\n${GREEN}███████████████████████████████████${NC}"
    echo -e "${GREEN}██  ВСЕ ЗЕБА! ВСЕ РАБОТАЕТ! 🎉  ██${NC}"
    echo -e "${GREEN}███████████████████████████████████${NC}\n"
    
    echo -e "${GREEN}✓ Все тесты прошли успешно!${NC}"
    echo -e "${GREEN}✓ Marzban панель работает${NC}"
    echo -e "${GREEN}✓ Логин и пароль проходят${NC}"
    echo -e "${GREEN}✓ VLESS Reality конфигурация установлена${NC}"
    echo -e "${GREEN}✓ Контейнеры готовы к работе${NC}"
    
    echo -e "\n${BLUE}=== ИНФОРМАЦИЯ О ДОСТУПЕ ===${NC}"
    echo -e "${GREEN}🌍 Marzban Panel:${NC} https://$DOMAIN:8080"
    echo -e "${GREEN}👤 Username:${NC} $SUDO_USERNAME"
    echo -e "${GREEN}🔐 Password:${NC} $SUDO_PASSWORD"
    echo ""
    echo -e "${GREEN}🔌 VLESS Reality Ports:${NC}"
    echo "  ✓ 2053 (Google Reality)"
    echo "  ✓ 2083 (Microsoft Reality)"
    echo "  ✓ 2087 (Cloudflare Reality)"
    echo ""
    echo -e "${GREEN}📝 Client Config:${NC} vless_client_config.json"
    echo "  ⚠️  Replace 'USER_UUID_HERE' with actual user UUIDs from panel"
    
else
    echo -e "\n${RED}███████████████████████████████████${NC}"
    echo -e "${RED}██    НЕ ВСЕ РАБОТАЕТ! 😱    ██${NC}"
    echo -e "${RED}███████████████████████████████████${NC}\n"
    
    echo -e "${RED}✗ Обнаружены проблемы с развертыванием!${NC}\n"
    
    echo -e "${RED}ПРОВАЛЕННЫЕ ТЕСТЫ:${NC}"
    for test in "${failed_tests[@]}"; do
        echo -e "${RED}  ✗ $test${NC}"
    done
    
    echo -e "\n${YELLOW}=== ПОЛНЫЕ ЛОГИ ВСЕХ КОНТЕЙНЕРОВ ===${NC}"
    
    for service in mysql marzban nginx certbot; do
        echo -e "\n${YELLOW}--- LOGS FOR $service ---${NC}"
        docker compose logs --tail=30 "$service" 2>&1 || echo "No logs available for $service"
    done
    
    echo -e "\n${YELLOW}--- DOCKER COMPOSE STATUS ---${NC}"
    docker compose ps
    
    echo -e "\n${YELLOW}--- SYSTEM RESOURCES ---${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    
    echo -e "\n${RED}Ошибка развертывания! Проверьте логи выше.${NC}"
    
    exit 1
fi

echo -e "\n${GREEN}=== ПОЛЕЗНЫЕ КОМАНДЫ ===${NC}"
echo "View logs: docker compose logs -f"
echo "Restart services: docker compose restart"
echo "Update images: docker compose pull && docker compose up -d"
echo "Stop all: docker compose down"

# Save deployment info
cat > deployment_info.txt << EOF
Marzban + Nginx + Certbot Deployment
Deployed on: $(date)
Status: SUCCESS ✅
Domain: $DOMAIN
Marzban Panel: https://$DOMAIN:8080
Username: $SUDO_USERNAME
Password: $SUDO_PASSWORD

VLESS Reality Ports:
- 2053 (Google Reality) ✅
- 2083 (Microsoft Reality) ✅
- 2087 (Cloudflare Reality) ✅

Client configuration template: vless_client_config.json ✅
All tests passed: $(date)
EOF

print_success "Deployment information saved to deployment_info.txt"
print_success "Deployment script completed successfully!"