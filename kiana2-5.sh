#!/bin/bash
set -euo pipefail

# =========================================
# 🚀 KIANA-2.6 FINAL SYNCED EDITION + EXPANDED REGIONS
# ✅ XRAY + NGINX TIMEOUT SYNCED (3600s) — NO TIMEOUT ON SPEEDTEST
# ✅ EXPANDED REGION MENU + DUAL LINKS + HEALTH CHECK
# ✅ NO PHONE OVERHEATING | LIGHTWEIGHT | STABLE
# ✅ FIXED CREDS: Pass=kiana-2.5 | UUID=a1b2c3d4-5678-40ef-98ab-cdef01234567
# =========================================

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
RAND=$(openssl rand -hex 3 2>/dev/null)
CLOUD_RUN_SERVICE_NAME="xray-balanced-$RAND"
BUILD_DIR=$(mktemp -d)

cleanup() { rm -rf "$BUILD_DIR" || true; }
trap cleanup EXIT

clear
echo ""
echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}     TROJAN + VLESS WS/TLS${NC}"
echo -e "${GREEN}     EXPANDED REGION EDITION${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}ERROR: No project set!${NC}"
    echo -e "Run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com --project="$PROJECT_ID" --quiet

# =========================================
# 🌏 EXPANDED REGION SELECTION MENU
# =========================================
echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}        SELECT DEPLOYMENT REGION${NC}"
echo -e "${CYAN}=========================================${NC}"
echo -e "${YELLOW}NOTE: Choose only regions available in your Google Cloud / Qwiklabs account${NC}"
echo ""
echo -e "--- 🇺🇸 UNITED STATES / GLOBAL ---"
echo -e "0) us-central1      (Iowa, USA)       | Default / Most Stable"
echo -e "1) us-east1         (South Carolina)"
echo -e "2) us-east4         (North Virginia)"
echo -e "3) us-west1         (Oregon, USA)"
echo -e "4) us-west2         (Los Angeles, USA)"
echo ""
echo -e "--- 🇵🇭🇸🇬🇹🇼 ASIA PACIFIC (FASTEST FOR PH) ---"
echo -e "5) asia-southeast1  (Singapore)       | #1 Fastest for SE Asia"
echo -e "6) asia-southeast2  (Jakarta, Indonesia)"
echo -e "7) asia-east1       (Taiwan)          | Very Fast for PH"
echo -e "8) asia-east2       (Hong Kong)"
echo -e "9) asia-northeast1  (Tokyo, Japan)"
echo -e "10) asia-northeast2 (Osaka, Japan)"
echo -e "11) asia-northeast3 (Seoul, South Korea)"
echo ""
echo -e "--- 🇪🇺 EUROPE / OTHERS ---"
echo -e "12) europe-west1    (Belgium)"
echo -e "13) europe-west2    (London, UK)"
echo -e "14) europe-west3    (Frankfurt, Germany)"
echo -e "15) europe-west4    (Netherlands)"
echo -e "16) australia-southeast1 (Sydney, Australia)"
echo ""

while true; do
    read -p "Select Region [0-16, press Enter for default=0]: " REG_SEL
    REG_SEL=${REG_SEL:-0}
    case "$REG_SEL" in
        0) REGION="us-central1"; break ;;
        1) REGION="us-east1"; break ;;
        2) REGION="us-east4"; break ;;
        3) REGION="us-west1"; break ;;
        4) REGION="us-west2"; break ;;
        5) REGION="asia-southeast1"; break ;;
        6) REGION="asia-southeast2"; break ;;
        7) REGION="asia-east1"; break ;;
        8) REGION="asia-east2"; break ;;
        9) REGION="asia-northeast1"; break ;;
        10) REGION="asia-northeast2"; break ;;
        11) REGION="asia-northeast3"; break ;;
        12) REGION="europe-west1"; break ;;
        13) REGION="europe-west2"; break ;;
        14) REGION="europe-west3"; break ;;
        15) REGION="europe-west4"; break ;;
        16) REGION="australia-southeast1"; break ;;
        *) echo -e "${RED}Invalid input! Enter a number from 0 to 16.${NC}" ;;
    esac
done

echo -e "${GREEN}✅ Selected Region:${NC} $REGION"
echo ""

echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}          BILLING MODE${NC}"
echo -e "${CYAN}=========================================${NC}"
echo -e "${YELLOW}Instance-Based = More Stable, No Throttling${NC}"
echo -e "1) Request-Based  |  2) Instance-Based"
while true; do
    read -p "Select [1-2]: " BILLING_CHOICE
    case $BILLING_CHOICE in
        1) BILLING_MODE="request"; break ;;
        2) BILLING_MODE="instance"; break ;;
        *) echo -e "${RED}Invalid input!${NC}" ;;
    esac
done

echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}      RESOURCE ALLOCATION${NC}"
echo -e "${CYAN}=========================================${NC}"
echo -e "${YELLOW}BALANCED: 2Gi RAM + 2vCPU | LIGHT: 1Gi RAM + 1vCPU${NC}"
echo -e "${YELLOW}BEST PERFORMANCE: 4Gi RAM + 4vCPU${NC}"
while true; do
    read -p "Memory [1=1Gi|2=2Gi|3=4Gi]: " MEM
    case $MEM in
        1) MEMORY="1Gi"; break ;;
        2) MEMORY="2Gi"; break ;;
        3) MEMORY="4Gi"; break ;;
    esac
done
while true; do
    read -p "vCPU [1=1|2=2|3=4]: " CPU_SEL
    case $CPU_SEL in
        1) CPU="1"; break ;;
        2) CPU="2"; break ;;
        3) CPU="4"; break ;;
    esac
done

if [ "$CPU" = "1" ] || [ "$MEMORY" = "1Gi" ]; then
    CONCURRENCY="300"
else
    CONCURRENCY="800"
fi
TIMEOUT="3600"

echo -e "${YELLOW}💡 Min Instances = 1 = No Disconnect / No Cold Start${NC}"
while true; do
    read -p "Min Instances [0/1, default=0]: " MIN_INST
    MIN_INST=${MIN_INST:-0}
    [[ "$MIN_INST" =~ ^[0-1]$ ]] && break || echo -e "${RED}Only 0 or 1 allowed${NC}"
done
while true; do
    read -p "Max Instances [1-2, default=1]: " MAX_INST
    MAX_INST=${MAX_INST:-1}
    [[ "$MAX_INST" =~ ^[1-2]$ ]] && break || echo -e "${RED}Only 1-2 allowed${NC}"
done

cd "$BUILD_DIR" || exit 1

# =========================
# ✅ XRAY POLICY: 3600s IDLE + LIGHTWEIGHT
# =========================
cat > config.json <<'EOF'
{
  "log": { "loglevel": "warning" },
  "policy": {
    "levels": {
      "0": {
        "handshake": 3,
        "connIdle": 3600,
        "uplinkOnly": 0,
        "downlinkOnly": 0,
        "bufferSize": 2097152
      }
    }
  },
  "inbounds": [
    {
      "tag": "trojan-ws",
      "port": 10001,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": { "clients": [{"password": "kiana-2.5", "level": 0}] },
      "sniffing": { "enabled": true, "destOverride": ["http","tls","quic"], "routeOnly": true },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/tr-ConFig?ed=2560", "maxEarlyData": 1048576 },
        "sockopt": {
          "tcpNoDelay": true,
          "tcpFastOpen": true,
          "tcpKeepAlive": true,
          "tcpKeepAliveIdle": 15,
          "tcpKeepAliveInterval": 10,
          "tcpKeepAliveCount": 5
        }
      }
    },
    {
      "tag": "vless-ws",
      "port": 10002,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": { "clients": [{"id": "a1b2c3d4-5678-40ef-98ab-cdef01234567", "level": 0}], "decryption": "none" },
      "sniffing": { "enabled": true, "destOverride": ["http","tls","quic"], "routeOnly": true },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/vl-ConFig?ed=2560", "maxEarlyData": 1048576 },
        "sockopt": {
          "tcpNoDelay": true,
          "tcpFastOpen": true,
          "tcpKeepAlive": true,
          "tcpKeepAliveIdle": 15,
          "tcpKeepAliveInterval": 10,
          "tcpKeepAliveCount": 5
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIPv4v6",
        "tcpKeepAliveIdle": 15,
        "tcpKeepAliveInterval": 10
      }
    }
  ]
}
EOF

# =========================
# ✅ NGINX: SYNCED PATHS + 3600s TIMEOUT + HEALTH CHECK
# =========================
cat > nginx.conf <<'EOF'
worker_processes auto;
worker_rlimit_nofile 65535;
worker_priority -10;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
    accept_mutex off;
}

http {
    include mime.types;
    default_type application/octet-stream;

    sendfile on;
    tcp_nodelay on;
    tcp_nopush on;
    types_hash_max_size 2048;

    keepalive_timeout 3600;
    keepalive_requests 10000;

    client_max_body_size 0;
    client_body_buffer_size 128k;

    proxy_buffering off;
    proxy_request_buffering off;
    proxy_cache off;
    proxy_http_version 1.1;
    proxy_set_header Connection "";

    proxy_connect_timeout 10s;
    proxy_send_timeout 3600s;
    proxy_read_timeout 3600s;

    server_tokens off;

    map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }

    server {
        listen 8080 deferred reuseport;
        server_name _;

        location /health {
            return 200 "OK\n";
            add_header Content-Type text/plain;
        }

        location / {
            proxy_pass https://www.google.com;
            proxy_set_header Host www.google.com;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_ssl_server_name on;
            proxy_ssl_protocols TLSv1.2 TLSv1.3;
        }

        location /tr-ConFig {
            proxy_pass http://127.0.0.1:10001;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_buffering off;
        }

        location /vl-ConFig {
            proxy_pass http://127.0.0.1:10002;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_buffering off;
        }
    }
}
EOF

cat > entrypoint.sh <<'EOF'
#!/bin/sh
/usr/local/bin/xray run -c /etc/xray.json &
sleep 3
exec /usr/local/openresty/bin/openresty -g 'daemon off;'
EOF
chmod +x entrypoint.sh

cat > Dockerfile <<'EOF'
FROM alpine:3.20 AS builder
RUN apk add --no-cache curl unzip ca-certificates
RUN curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o xray.zip \
 && unzip -q xray.zip xray geosite.dat geoip.dat \
 && chmod +x xray

FROM openresty/openresty:alpine-fat
RUN apk add --no-cache ca-certificates tzdata bash

COPY --from=builder /xray /usr/local/bin/xray
COPY --from=builder /geosite.dat /usr/local/share/xray/
COPY --from=builder /geoip.dat /usr/local/share/xray/
COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /usr/local/bin/xray /entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
EOF

echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}          BUILDING IMAGE${NC}"
echo -e "${CYAN}=========================================${NC}"
gcloud builds submit --project="$PROJECT_ID" --tag gcr.io/$PROJECT_ID/$CLOUD_RUN_SERVICE_NAME . --quiet

BILLING_FLAGS=$([ "$BILLING_MODE" = "instance" ] && echo "--no-cpu-throttling" || echo "--cpu-throttling")

echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}         DEPLOYING TO CLOUD RUN${NC}"
echo -e "${CYAN}=========================================${NC}"
gcloud run deploy $CLOUD_RUN_SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$CLOUD_RUN_SERVICE_NAME \
  --project="$PROJECT_ID" --platform managed --region "$REGION" --allow-unauthenticated \
  --port 8080 --memory $MEMORY --cpu $CPU --concurrency $CONCURRENCY \
  --timeout $TIMEOUT --min-instances $MIN_INST --max-instances $MAX_INST \
  --execution-environment gen2 --cpu-boost $BILLING_FLAGS --quiet

# Get Dual Links
CLOUD_RUN_URL=$(gcloud run services describe $CLOUD_RUN_SERVICE_NAME --project="$PROJECT_ID" --region="$REGION" --format='value(status.url)')
DOMAIN=$(echo "$CLOUD_RUN_URL" | sed 's|https://||')
FULL_DOMAIN=$(gcloud run services describe $CLOUD_RUN_SERVICE_NAME --project="$PROJECT_ID" --region="$REGION" --format='value(status.addresses[0].url)' | sed 's|https://||')

echo -e "\n${CYAN}=========================================${NC}"
echo -e "${GREEN}✅ DEPLOYMENT SUCCESS!${NC}"
echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}Service:${NC} $CLOUD_RUN_SERVICE_NAME"
echo -e "${GREEN}🔗 SHORT LINK:${NC} https://$DOMAIN"
echo -e "${GREEN}🔗 FULL LINK:${NC} https://$FULL_DOMAIN"
echo -e "${GREEN}💚 HEALTH CHECK:${NC} https://$FULL_DOMAIN/health"
echo -e "${GREEN}Port:${NC} 443"
echo -e "\n${YELLOW}--- RECOMMENDED SETTINGS ---${NC}"
echo -e "${YELLOW}👉 FASTEST FOR PH: Singapore(5) / Taiwan(7)${NC}"
echo -e "${YELLOW}👉 BALANCED & SAFE: 2Gi RAM + 2vCPU + Instance-Based${NC}"
echo -e "${YELLOW}👉 BEST PERFORMANCE: 4Gi RAM + 4vCPU + Instance-Based${NC}"
echo -e "\n${YELLOW}--- CLIENT CONFIGS ---${NC}"
echo -e "${GREEN}🔹 TROJAN + WS + TLS${NC}"
echo "   Address: $FULL_DOMAIN"
echo "   Port: 443"
echo "   Password: kiana-2.5"
echo "   Path: /tr-ConFig?ed=2560"
echo "   SNI: $FULL_DOMAIN"
echo -e "\n${GREEN}🔹 VLESS + WS + TLS${NC}"
echo "   Address: $FULL_DOMAIN"
echo "   Port: 443"
echo "   UUID: a1b2c3d4-5678-40ef-98ab-cdef01234567"
echo "   Path: /vl-ConFig?ed=2560"
echo "   SNI: $FULL_DOMAIN"
echo -e "${CYAN}=========================================${NC}"
echo -e "${YELLOW}💡 XRAY + NGINX TIMEOUT SYNCED | LIGHTWEIGHT | NO DISCONNECT${NC}"
