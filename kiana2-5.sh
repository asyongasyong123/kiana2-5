#!/bin/bash
set -euo pipefail

# =========================================
# 🚀 KIANA-2.6.5 | FULL SELECTIONS + MOBILE-FRIENDLY
# ✅ ALL OPTIONS: REGION / MEMORY / CPU / BILLING / INSTANCES
# ✅ NO MORE INFINITE ERROR LOOP
# ✅ AUTO-CLEAN INPUT FOR MOBILE KEYBOARD
# ✅ 100% CLOUD RUN COMPLIANT
# ✅ CREDS: Pass=kiana-2.5 | UUID=a1b2c3d4-5678-40ef-98ab-cdef01234567
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
echo -e "${GREEN}     KIANA-2.6.5 FULL SELECT EDITION${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ ERROR: No GCP Project found!${NC}"
    echo -e "👉 Run first: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com --project="$PROJECT_ID" --quiet

# =========================================
# 🌏 REGION SELECT (FULL LIST)
# =========================================
echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}        📌 SELECT DEPLOYMENT REGION${NC}"
echo -e "${CYAN}=========================================${NC}"
echo -e "${YELLOW}👉 Type NUMBER only, press ENTER. Auto default if wrong${NC}"
echo ""
echo -e "0) us-central1      (Iowa, USA)       | Default"
echo -e "1) us-east1         (South Carolina)"
echo -e "2) us-east4         (North Virginia)"
echo -e "3) us-west1         (Oregon, USA)"
echo -e "4) us-west2         (Los Angeles, USA)"
echo -e "5) asia-southeast1  (Singapore)       | ⚡ FASTEST PH"
echo -e "6) asia-southeast2  (Jakarta)"
echo -e "7) asia-east1       (Taiwan)          | ⚡ FAST PH"
echo -e "8) asia-east2       (Hong Kong)"
echo -e "9) asia-northeast1  (Tokyo)"
echo -e "10) asia-northeast2 (Osaka)"
echo -e "11) asia-northeast3 (Seoul)"
echo -e "12) europe-west1    (Belgium)"
echo -e "13) europe-west2    (London)"
echo -e "14) europe-west3    (Frankfurt)"
echo -e "15) europe-west4    (Netherlands)"
echo -e "16) australia-southeast1 (Sydney)"
echo ""

read REG_SEL
REG_SEL=$(echo "$REG_SEL" | tr -cd '0-9')
case "$REG_SEL" in
    1) REGION="us-east1" ;;
    2) REGION="us-east4" ;;
    3) REGION="us-west1" ;;
    4) REGION="us-west2" ;;
    5) REGION="asia-southeast1" ;;
    6) REGION="asia-southeast2" ;;
    7) REGION="asia-east1" ;;
    8) REGION="asia-east2" ;;
    9) REGION="asia-northeast1" ;;
    10) REGION="asia-northeast2" ;;
    11) REGION="asia-northeast3" ;;
    12) REGION="europe-west1" ;;
    13) REGION="europe-west2" ;;
    14) REGION="europe-west3" ;;
    15) REGION="europe-west4" ;;
    16) REGION="australia-southeast1" ;;
    *) REGION="us-central1" ;;
esac
echo -e "${GREEN}✅ Selected Region: $REGION${NC}"
echo ""

# =========================================
# 💰 BILLING MODE
# =========================================
echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}        💳 BILLING MODE${NC}"
echo -e "${CYAN}=========================================${NC}"
echo -e "1) Request-Based  |  2) Instance-Based ✅ Recommended"
read BILLING_CHOICE
BILLING_CHOICE=$(echo "$BILLING_CHOICE" | tr -cd '0-9')
if [ "$BILLING_CHOICE" = "1" ]; then
    BILLING_MODE="request"
    BILLING_FLAGS="--cpu-throttling"
else
    BILLING_MODE="instance"
    BILLING_FLAGS="--no-cpu-throttling"
fi
echo -e "${GREEN}✅ Billing Mode: $BILLING_MODE${NC}"
echo ""

# =========================================
# ⚙️ MEMORY & vCPU
# =========================================
echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}        📊 RESOURCE ALLOCATION${NC}"
echo -e "${CYAN}=========================================${NC}"
echo -e "0 = 1Gi / 1vCPU  |  1 = 2Gi / 2vCPU ✅ Balanced  |  2 = 4Gi / 4vCPU ✅ Fastest"
read RES_SEL
RES_SEL=$(echo "$RES_SEL" | tr -cd '0-9')
if [ "$RES_SEL" = "0" ]; then
    MEMORY="1Gi"; CPU="1"; CONCURRENCY="300"
elif [ "$RES_SEL" = "2" ]; then
    MEMORY="4Gi"; CPU="4"; CONCURRENCY="800"
else
    MEMORY="2Gi"; CPU="2"; CONCURRENCY="800"
fi
TIMEOUT="3600"
echo -e "${GREEN}✅ Resources: $MEMORY RAM | $CPU vCPU${NC}"
echo ""

# =========================================
# 🚀 INSTANCE SETTINGS
# =========================================
echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}        🚀 INSTANCE SETTINGS${NC}"
echo -e "${CYAN}=========================================${NC}"
read -p "Min Instances [0/1, default=1]: " MIN_INST
MIN_INST=$(echo "$MIN_INST" | tr -cd '0-9')
if [ "$MIN_INST" != "0" ]; then MIN_INST="1"; fi

read -p "Max Instances [1/2, default=1]: " MAX_INST
MAX_INST=$(echo "$MAX_INST" | tr -cd '0-9')
if [ "$MAX_INST" != "2" ]; then MAX_INST="1"; fi
echo -e "${GREEN}✅ Min: $MIN_INST | Max: $MAX_INST${NC}"
echo ""

cd "$BUILD_DIR" || exit 1

# =========================
# ✅ XRAY CONFIG
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
# ✅ NGINX CONFIG
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

        location /tr-ConFig {
            proxy_pass http://127.0.0.1:10001;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_buffering off;
        }

        location /vl-ConFig {
            proxy_pass http://127.0.0.1:10002;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
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
echo -e "${GREEN}          🔨 BUILDING IMAGE${NC}"
echo -e "${CYAN}=========================================${NC}"
gcloud builds submit --project="$PROJECT_ID" --tag gcr.io/$PROJECT_ID/$CLOUD_RUN_SERVICE_NAME . --quiet

echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}         🚀 DEPLOYING TO CLOUD RUN${NC}"
echo -e "${CYAN}=========================================${NC}"
gcloud run deploy $CLOUD_RUN_SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$CLOUD_RUN_SERVICE_NAME \
  --project="$PROJECT_ID" --platform managed --region "$REGION" --allow-unauthenticated \
  --port 8080 --memory $MEMORY --cpu $CPU --concurrency $CONCURRENCY \
  --timeout $TIMEOUT --min-instances $MIN_INST --max-instances $MAX_INST \
  --execution-environment gen2 --cpu-boost $BILLING_FLAGS --quiet

# GET LINKS
CLOUD_RUN_URL=$(gcloud run services describe $CLOUD_RUN_SERVICE_NAME --project="$PROJECT_ID" --region="$REGION" --format='value(status.url)')
DOMAIN=$(echo "$CLOUD_RUN_URL" | sed 's|https://||')
FULL_DOMAIN=$(gcloud run services describe $CLOUD_RUN_SERVICE_NAME --project="$PROJECT_ID" --region="$REGION" --format='value(status.addresses[0].url)' | sed 's|https://||')

echo -e "\n${CYAN}=========================================${NC}"
echo -e "${GREEN}✅ 🎉 DEPLOYMENT SUCCESS! 🎉${NC}"
echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}📍 Region:${NC} $REGION"
echo -e "${GREEN}⚙️ Resources:${NC} $MEMORY RAM | $CPU vCPU"
echo -e "${GREEN}💳 Billing:${NC} $BILLING_MODE"
echo -e "${GREEN}🔗 Full Link:${NC} https://$FULL_DOMAIN"
echo -e "${GREEN}💚 Health Check:${NC} https://$FULL_DOMAIN/health"
echo -e "\n${YELLOW}--- CLIENT CONFIGS ---${NC}"
echo -e "${GREEN}🔹 TROJAN:${NC} $FULL_DOMAIN:443 | kiana-2.5 | /tr-ConFig?ed=2560"
echo -e "${GREEN}🔹 VLESS:${NC} $FULL_DOMAIN:443 | a1b2c3d4-5678-40ef-98ab-cdef01234567 | /vl-ConFig?ed=2560"
echo -e "${CYAN}=========================================${NC}"
