#!/bin/bash

# Script to generate VLESS Reality keys and update configuration
# Usage: ./generate-keys.sh

set -e

echo "🔐 Generating VLESS Reality keys..."

# Wait for Marzban container to be ready
echo "⏳ Waiting for Marzban container to be ready..."
while ! docker compose ps | grep -q "marzban.*Up"; do
    echo "Waiting for Marzban container..."
    sleep 5
done

echo "✅ Marzban container is ready"

# Generate X25519 keys
echo "🔑 Generating X25519 key pair..."
key_output=$(docker compose exec -T marzban xray x25519)
if [ $? -ne 0 ]; then
    echo "❌ Failed to generate X25519 keys"
    exit 1
fi

echo "$key_output"

# Extract private and public keys
private_key=$(echo "$key_output" | grep "Private key:" | cut -d' ' -f3)
public_key=$(echo "$key_output" | grep "Public key:" | cut -d' ' -f3)

if [ -z "$private_key" ] || [ -z "$public_key" ]; then
    echo "❌ Failed to extract keys from output"
    echo "Output was: $key_output"
    exit 1
fi

echo "✅ Private key: $private_key"
echo "✅ Public key: $public_key"

# Generate short IDs
echo "🎲 Generating short IDs..."
short_id1=$(openssl rand -hex 8)
short_id2=$(openssl rand -hex 8)
short_id3=$(openssl rand -hex 8)

echo "✅ Short IDs: $short_id1, $short_id2, $short_id3"

# Update .env file
echo "📝 Updating .env file..."
cp .env .env.backup

# Update environment variables
sed -i "s/VLESS_PRIVATE_KEY=.*/VLESS_PRIVATE_KEY=$private_key/" .env
sed -i "s/VLESS_PUBLIC_KEY=.*/VLESS_PUBLIC_KEY=$public_key/" .env
sed -i "s/VLESS_SHORT_IDS=.*/VLESS_SHORT_IDS=$short_id1,$short_id2,$short_id3/" .env

echo "✅ .env file updated"

# Update Xray configuration
echo "🔧 Updating Xray configuration..."
cp xray_config.json xray_config.json.backup

# Replace placeholders in xray_config.json
sed -i "s/{{VLESS_PRIVATE_KEY}}/$private_key/g" xray_config.json
sed -i "s/{{VLESS_SHORT_IDS}}/$short_id1/g" xray_config.json

echo "✅ Xray configuration updated"

# Create client configuration template
echo "📝 Creating client configuration template..."
cat > vless_client_config.json << EOF
{
  "remarks": "Marzban VLESS Reality - Port 2053",
  "log": {
    "level": "warning"
  },
  "inbounds": [
    {
      "tag": "socks",
      "port": 10808,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      },
      "settings": {
        "auth": "noauth",
        "udp": false
      }
    },
    {
      "tag": "http",
      "port": 10809,
      "listen": "127.0.0.1",
      "protocol": "http",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "botinger789298.work.gd",
            "port": 2053,
            "users": [
              {
                "id": "USER_UUID_HERE",
                "flow": "",
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "fingerprint": "chrome",
          "serverName": "www.google.com",
          "publicKey": "$public_key",
          "shortId": "$short_id1",
          "spiderX": "/"
        }
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIP"
      }
    },
    {
      "tag": "block",
      "protocol": "blackhole",
      "settings": {
        "response": {
          "type": "http"
        }
      }
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "inboundTag": ["api"],
        "outboundTag": "api"
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": ["domain:ru", "geosite:ru"]
      },
      {
        "type": "field",
        "outboundTag": "proxy",
        "network": "tcp,udp"
      }
    ]
  }
}
EOF

echo "✅ Client configuration template created: vless_client_config.json"

# Restart Marzban to apply changes
echo "🔄 Restarting Marzban to apply changes..."
docker compose restart marzban

echo "⏳ Waiting for Marzban to restart..."
sleep 15

echo "🎉 VLESS Reality keys generated and configured successfully!"
echo ""
echo "📝 Configuration Summary:"
echo "  Private Key: $private_key"
echo "  Public Key: $public_key"
echo "  Short IDs: $short_id1, $short_id2, $short_id3"
echo ""
echo "🌐 VLESS Reality Ports:"
echo "  - 2053 (Google Reality)"
echo "  - 2083 (Microsoft Reality)"
echo "  - 2087 (Cloudflare Reality)"
echo ""
echo "📝 Client configuration template saved as: vless_client_config.json"
echo "    Replace 'USER_UUID_HERE' with actual user UUID from Marzban panel"
echo ""
echo "🔗 Marzban Panel: https://botinger789298.work.gd:8080"
echo "    Username: artur789298"
echo "    Password: WARpteN789298"