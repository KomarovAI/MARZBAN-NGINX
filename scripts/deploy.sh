#!/bin/bash

# Complete deployment script for Marzban + Nginx + Certbot
# Usage: ./deploy.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_header "Checking prerequisites and installing Docker/Docker Compose if needed"

# Detect package manager
if [ -x "$(command -v apt-get)" ]; then
    PKG="apt-get"
    DOCKER_PKGS="docker.io docker-compose-plugin curl openssl jq"
    INSTALL_CMD="sudo apt-get install -y"
elif [ -x "$(command -v yum)" ]; then
    PKG="yum"
    DOCKER_PKGS="docker docker-compose curl openssl jq"
    INSTALL_CMD="sudo yum install -y"
else
    print_error "Unsupported OS. Only apt-get (Debian/Ubuntu) and yum (CentOS/RHEL) are supported."
    exit 1
fi

if ! command -v docker &>/dev/null; then
    print_warning "Docker not found. Installing Docker..."
    $INSTALL_CMD $DOCKER_PKGS
    if command -v docker &>/dev/null; then
        print_success "Docker installed successfully."
        sudo systemctl enable --now docker
        sudo usermod -aG docker $USER
    else
        print_error "Failed to install Docker. Aborting."
        exit 1
    fi
else
    print_status "Docker is already installed."
fi

if ! command -v docker-compose &>/dev/null && ! docker compose version &>/dev/null; then
    print_warning "Docker Compose not found. Attempting to install..."
    $INSTALL_CMD $DOCKER_PKGS
    if command -v docker-compose &>/dev/null || docker compose version &>/dev/null; then
        print_success "Docker Compose installed successfully."
    else
        print_error "Failed to install Docker Compose. Aborting."
        exit 1
    fi
else
    print_status "Docker Compose is already installed."
fi

print_status "Docker and Docker Compose available. Continuing deployment..."

# ... (весь остальной скрипт тестов, развертывания и проверки как выше) ...