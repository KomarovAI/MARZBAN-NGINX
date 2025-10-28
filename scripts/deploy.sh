#!/bin/bash

# Robust deployment script for Marzban + Nginx + Certbot + Reality
# Usage: ./scripts/deploy.sh
# Idempotent: safe to re-run. Performs preflight checks, DNS/ports/SSL, generates keys, boots stack, verifies health.

set -Eeuo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*"; }
head() { echo -e "\n${BLUE}=== $* ===${NC}\n"; }
ok()   { echo -e "${GREEN}✓${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*"; }

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

trap 'err "Unexpected error on line $LINENO"; tail -n 200 docker-compose.log 2>/dev/null || true; exit 1' ERR

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Required command '$1' not found"; return 1; }
}

pm=""
if command -v apt-get >/dev/null 2>&1; then pm="apt"; fi
if [ -z "$pm" ] && command -v yum >/dev/null 2>&1; then pm="yum"; fi
[ -n "$pm" ] || { err "Unsupported OS. Need apt or yum"; exit 1; }

head "Installing prerequisites (Docker, Compose, curl, openssl, jq, dig, socat)"
if [ "$pm" = "apt" ]; then
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg lsb-release jq openssl dnsutils net-tools socat
  if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  fi
elif [ "$pm" = "yum" ]; then
  sudo yum install -y yum-utils jq openssl bind-utils net-tools socat curl
  sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || true
  if ! command -v docker >/dev/null 2>&1; then
    sudo yum install -y docker-ce docker-ce-cli containerd.io
  fi
  if ! docker compose version >/dev/null 2>&1; then
    warn "Docker Compose v2 plugin not detected; attempting to install";
    # On many RHEL clones compose v2 ships with docker-ce-plugin-compose package
    sudo yum install -y docker-compose-plugin || true
  fi
fi
sudo systemctl enable --now docker || true
sudo usermod -aG docker "$USER" || true

require_cmd docker
if ! docker compose version >/dev/null 2>&1; then
  warn "docker compose plugin not found; falling back to docker-compose (if present)"
  require_cmd docker-compose || { err "Install docker compose plugin or docker-compose"; exit 1; }
fi

head ".env validation"
[ -f .env ] || { err ".env not found"; exit 1; }
set -a; source .env; set +a
: "${DOMAIN:?DOMAIN is required in .env}"
: "${SSL_EMAIL:?SSL_EMAIL is required in .env}"
: "${SERVER_IP:?SERVER_IP is required in .env}"
: "${SUDO_USERNAME:?SUDO_USERNAME is required in .env}"
: "${SUDO_PASSWORD:?SUDO_PASSWORD is required in .env}"
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required in .env}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is required in .env}"

ok "Loaded .env for domain $DOMAIN and IP $SERVER_IP"

head "DNS A-record check"
current_ip=$(dig +short A "$DOMAIN" | tail -n1 || true)
if [ -z "$current_ip" ]; then
  err "DNS A record not found for $DOMAIN"; exit 1
fi
if [ "$current_ip" != "$SERVER_IP" ]; then
  err "DNS mismatch: $DOMAIN -> $current_ip, expected $SERVER_IP"; exit 1
fi
ok "DNS points to $SERVER_IP"

head "Port availability check"
check_port_free() {
  local p="$1"
  if ss -tulpn 2>/dev/null | grep -q ":$p\b"; then
    err "Port $p is already in use"; return 1; else ok "Port $p is free"; fi
}
# Only check public ports; mysql and app ports are bound to 127.0.0.1
for p in 8080 2053 2083 2087; do check_port_free "$p"; done

head "Folder structure and permissions"
mkdir -p certbot/conf certbot/www nginx/conf.d /var/lib/marzban /var/lib/marzban/mysql
sudo chown -R "$USER":"$USER" certbot || true
sudo chown -R 999:999 /var/lib/marzban/mysql || true
ok "Directories prepared"

head "SSL certificates pre-check"
CERT_PATH="certbot/conf/live/$DOMAIN/fullchain.pem"
KEY_PATH="certbot/conf/live/$DOMAIN/privkey.pem"
if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
  ok "Existing certificate found for $DOMAIN"
else
  warn "No certificate found; attempting standalone issuance"
  # Stop anything on 80 if present (acme http-01 needs 80); fallback to TLS-ALPN-01 over 443 if 80 busy
  CAN_USE_80=true
  if ss -tulpn 2>/dev/null | grep -q ":80\b"; then CAN_USE_80=false; fi
  if [ "$CAN_USE_80" = true ]; then
    docker run --rm -p 80:80 -v "$PWD/certbot/conf:/etc/letsencrypt" -v "$PWD/certbot/www:/var/www/certbot" certbot/certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos -m "$SSL_EMAIL" --preferred-challenges http-01
  else
    warn "Port 80 is busy; trying TLS-ALPN-01 on 443"
    if ss -tulpn 2>/dev/null | grep -q ":443\b"; then err "443 is busy; free either 80 or 443 for initial issuance"; exit 1; fi
    docker run --rm -p 443:443 -v "$PWD/certbot/conf:/etc/letsencrypt" certbot/certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos -m "$SSL_EMAIL" --preferred-challenges tls-alpn-01
  fi
  [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ] || { err "Certificate issuance failed"; exit 1; }
  ok "Certificate issued for $DOMAIN"
fi

head "VLESS Reality keys"
if grep -q '{{VLESS_PRIVATE_KEY}}' xray_config.json; then
  : # template style
fi
if [ -z "${VLESS_PRIVATE_KEY:-}" ] || [ -z "${VLESS_SHORT_IDS:-}" ]; then
  warn "VLESS keys missing in .env; generating via scripts/generate-keys.sh"
  chmod +x scripts/generate-keys.sh
  scripts/generate-keys.sh || { err "Key generation failed"; exit 1; }
  set -a; source .env; set +a
fi
[ -n "${VLESS_PRIVATE_KEY:-}" ] && [ -n "${VLESS_SHORT_IDS:-}" ] || { err "VLESS keys still absent after generation"; exit 1; }
ok "Reality keys present"

head "Compose sanity and images"
require_cmd docker
compose_cmd="docker compose"
$compose_cmd version >/dev/null 2>&1 || compose_cmd="docker-compose"
$compose_cmd config -q || { err "docker-compose config validation failed"; exit 1; }
log "Pulling images"
$compose_cmd pull | tee docker-compose.log

head "Booting stack"
$compose_cmd up -d | tee -a docker-compose.log
sleep 5
$compose_cmd ps

head "Health checks"
log "Waiting for MySQL to accept connections..."
for i in $(seq 1 40); do
  if docker exec -i marzban_mysql mysqladmin ping -uroot -p"$MYSQL_ROOT_PASSWORD" --silent 2>/dev/null; then ok "MySQL is up"; break; fi; sleep 3; done
if ! docker exec -i marzban_mysql mysqladmin ping -uroot -p"$MYSQL_ROOT_PASSWORD" --silent 2>/dev/null; then err "MySQL failed to become ready"; $compose_cmd logs mysql; exit 1; fi

log "Checking Marzban HTTP on 127.0.0.1:8000"
for i in $(seq 1 40); do
  if curl -sk --max-time 2 http://127.0.0.1:8000/docs >/dev/null; then ok "Marzban backend responding"; break; fi; sleep 3; done
if ! curl -sk --max-time 2 http://127.0.0.1:8000/docs >/dev/null; then err "Marzban not responding"; $compose_cmd logs marzban; exit 1; fi

log "Checking Nginx TLS on https://$DOMAIN:8080"
for i in $(seq 1 40); do
  if curl -skI --max-time 3 https://"$DOMAIN":8080 | grep -qi "200\|301\|302"; then ok "Panel reachable over TLS"; break; fi; sleep 3; done
if ! curl -skI --max-time 3 https://"$DOMAIN":8080 >/dev/null; then err "Panel not reachable on 8080"; $compose_cmd logs nginx; exit 1; fi

head "Firewall guidance (UFW)"
if command -v ufw >/dev/null 2>&1; then
  warn "Ensure UFW allows 8080/tcp 2053/tcp 2083/tcp 2087/tcp"
  sudo ufw allow 8080/tcp || true
  sudo ufw allow 2053/tcp || true
  sudo ufw allow 2083/tcp || true
  sudo ufw allow 2087/tcp || true
fi

head "Summary"
cat <<EOF
Domain: https://$DOMAIN:8080
Admin:  $SUDO_USERNAME
Notes:
 - Certificates stored in ./certbot/conf/live/$DOMAIN/
 - Reality ports open: 2053 (Google), 2083 (Microsoft), 2087 (Cloudflare)
 - Re-run this script safely at any time; idempotent checks included
EOF
ok "Deployment completed successfully"
