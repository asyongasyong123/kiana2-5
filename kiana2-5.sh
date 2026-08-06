#!/bin/bash
set -euo pipefail

# =========================================
# 🚀 KIANA-2.6.6 | NO LOOP + FULL SELECTIONS + MOBILE-FRIENDLY
# ✅ ALL SETTINGS KEPT: REGION / MEM / CPU / BILLING / INSTANCES
# ✅ NO MORE INFINITE ERROR LOOP — AUTO DEFAULT IF WRONG
# ✅ PERFECT FOR MOBILE CLOUD SHELL
# ✅ CLOUD RUN COMPLIANT
# =========================================

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
RAND=$(openssl rand -hex 3 2>/dev/null)
CLOUD_RUN_SERVICE_NAME="xray-kiana-$RAND"
BUILD_DIR=$(mktemp -d)

cleanup() { rm -rf "$BUILD_DIR" || true; }
trap cleanup EXIT

clear
echo ""
echo -e "${CYAN}================================================================${NC}"
echo -e "${GREEN}                    FOR CLOUDSHELL${NC}"
echo -e "${GREEN}            KIANA-2.5 GCP DEPLOYER BY Con Fig${NC}"
echo -e "${GREEN}         TROJAN & VLESS + WS + TLS PROTOCOLS ONLY${NC}"
echo -e "${GREEN}       SIMPLE CODED,LIGHTWEIGHT XRAY.JSON & NGINX.CONF${NC}"
echo -e "${GREEN}    MANUAL SET UP FOR REGION,INSTANCES,BILLING,MEMORY & vCPU${NC}"
echo -e "${CYAN}====================================================÷÷÷÷÷÷÷÷÷===${NC}"
echo ""

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ ERROR: No project found!${NC}"
    exit 1
fi

gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com --project="$PROJECT_ID" --quiet

# =========================================
# 🌏 REGION SELECT (NO LOOP)
# =========================================
echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}        🌏 SELECT REGION${NC}"
echo -e "${CYAN}=========================================${NC}"
echo -e "0) us-central1      | US Iowa (Default)"
echo -e "1) us-east1         | US South Carolina"
echo -e "5) asia-southeast1  | Singapore ⚡ FASTEST"
echo -e "7) asia-east1       | Taiwan ⚡ FAST"
echo -e "9) asia-northeast1  | Tokyo"
echo -e "14) europe-west3    | Frankfurt"
echo -e "16) sydney          | Australia"
echo ""
read -p "Enter Region Number: " REG_SEL
REG_SEL=$(echo "$REG_SEL" | tr -cd '0-9')

case "$REG_SEL" in
    1) REGION="us-east1" ;;
    5) REGION="asia-southeast1" ;;
    7) REGION="asia-east1" ;;
    9) REGION="asia-northeast1" ;;
    14) REGION="europe-west3" ;;
    16) REGION="australia-southeast1" ;;
    *) REGION="us-central1" ;;
esac
echo -e "${GREEN}✅ Region: $REGION${NC}"
echo ""

# =========================================
# 💰 BILLING MODE
# =========================================
read -p "Billing: 1=Request | 2=Instance [2]: " BILLING_CHOICE
BILLING_CHOICE=$(echo "$BILLING_CHOICE" | tr -cd '0-9')
if [ "$BILLING_CHOICE" = "1" ]; then
    BILLING_FLAGS="--cpu-throttling"
else
    BILLING_FLAGS="--no-cpu-throttling"
fi
echo -e "${GREEN}✅ Billing: Instance-Based${NC}"
echo ""

# =========================================
# ⚙️ MEMORY & CPU
# =========================================
read -p "Resource: 0=1Gi/1vCPU | 1=2Gi/2vCPU | 2=4Gi/4vCPU [1]: " RES_SEL
RES_SEL=$(echo "$RES_SEL" | tr -cd '0-9')
if [ "$RES_SEL" = "0" ]; then
    MEMORY="1Gi"; CPU="1"; CONCURRENCY="300"
elif [ "$RES_SEL" = "2" ]; then
    MEMORY="4Gi"; CPU="4"; CONCURRENCY="800"
else
    MEMORY="2Gi"; CPU="2"; CONCURRENCY="800"
fi
TIMEOUT="3600"
echo -e "${GREEN}✅ Resources: $MEMORY | $CPU vCPU${NC}"
echo ""

# =========================================
# 🚀 INSTANCES
# =========================================
read -p "Min Instances [0/1, 1=Stable]: " MIN_INST
MIN_INST=$(echo "$MIN_INST" | tr -cd '0-9')
[ "$MIN_INST" != "0" ] && MIN_INST="1"

read -p "Max Instances [1/2]: " MAX_INST
MAX_INST=$(echo "$MAX_INST" | tr -cd '0-9')
[ "$MAX_INST" != "2" ] && MAX_INST="1"
echo -e "${GREEN}✅ Min: $MIN_INST | Max: $MAX_INST${NC}"
echo ""

cd "$BUILD_DIR" || exit 1

# =========================
# ✅ XRAY CONFIG
# =========================
cat > config.json <<'EOF'
{
  "log": { "loglevel": "warning" },
  "policy": { "levels": { "0": { "connIdle": 3600, "bufferSize": 2097152 } } },
  "inbounds": [
    {
      "tag": "trojan", "port": 10001, "listen": "127.0.0.1", "protocol": "trojan",
      "settings": { "clients": [{"password": "kiana-2.5"}] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/tr-Cfg" } }
    },
    {
      "tag": "vless", "port": 10002, "listen": "127.0.0.1", "protocol": "vless",
      "settings": { "clients": [{"id": "a1b2c3d4-5678-40ef-98ab-cdef01234567"}], "decryption": "none" },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vl-Cfg" } }
    }
  ],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

# =========================
# ✅ NGINX CONFIG
# =========================
cat > nginx.conf <<'EOF'
worker_processes auto;
events { worker_connections 4096; }
http {
    sendfile on;
    keepalive_timeout 3600;
    proxy_read_timeout 3600s;
    server {
        listen 8080;
        location /health { return 200 "OK"; }
        location /tr-Cfg { proxy_pass http://127.0.0.1:10001; proxy_set_header Upgrade $http_upgrade; }
        location /vl-Cfg { proxy_pass http://127.0.0.1:10002; proxy_set_header Upgrade $http_upgrade; }
    }
}
EOF

cat > entrypoint.sh <<'EOF'
#!/bin/sh
/usr/local/bin/xray run -c /etc/xray.json &
sleep 2
exec openresty -g 'daemon off;'
EOF
chmod +x entrypoint.sh

cat > Dockerfile <<'EOF'
FROM alpine:3.20 AS builder
RUN apk add --no-cache curl unzip
RUN curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip | unzip -q - xray
FROM openresty/openresty:alpine-fat
COPY --from=builder /xray /usr/local/bin/
COPY config.json /etc/xray.json
COPY nginx.conf /etc/nginx/conf/nginx.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
EOF

echo -e "${CYAN}🔨 BUILDING...${NC}"
gcloud builds submit --project="$PROJECT_ID" --tag gcr.io/$PROJECT_ID/$CLOUD_RUN_SERVICE_NAME . --quiet

echo -e "${CYAN}🚀 DEPLOYING...${NC}"
gcloud run deploy $CLOUD_RUN_SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$CLOUD_RUN_SERVICE_NAME \
  --platform managed --region "$REGION" --allow-unauthenticated \
  --memory $MEMORY --cpu $CPU --concurrency $CONCURRENCY \
  --timeout $TIMEOUT --min-instances $MIN_INST --max-instances $MAX_INST \
  --execution-environment gen2 $BILLING_FLAGS --quiet

DOMAIN=$(gcloud run services describe $CLOUD_RUN_SERVICE_NAME --region="$REGION" --format='value(status.url)' | sed 's|https://||')

echo -e "\n${CYAN}=========================================${NC}"
echo -e "${GREEN}✅ SUCCESS!${NC}"
echo -e "${GREEN}🔗 LINK: https://$DOMAIN${NC}"
echo -e "${GREEN}💚 HEALTH: https://$DOMAIN/health${NC}"
echo -e "${CYAN}=========================================${NC}"
