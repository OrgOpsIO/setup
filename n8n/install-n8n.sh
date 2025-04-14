#!/bin/bash

# ---------------------------------------------
# n8n Docker-Compose Installation 
# ---------------------------------------------

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}n8n installation started...${NC}"

# Check if Traefik is running
echo -e "${YELLOW}Checking for existing Traefik instance...${NC}"
if docker ps | grep -q "0.0.0.0:80\|0.0.0.0:443\|:::80\|:::443"; then
    TRAEFIK_RUNNING=true
    echo -e "${YELLOW}A service is already running on ports 80/443. Traefik will not be started.${NC}"
else
    TRAEFIK_RUNNING=false
    echo -e "${YELLOW}No service found on ports 80/443. You should run Traefik first.${NC}"
    echo -e "${YELLOW}Do you want to continue anyway? (y/n)${NC}"
    read -r response
    if [[ "$response" != "y" && "$response" != "Y" ]]; then
        echo -e "${RED}n8n installation aborted.${NC}"
        exit 1
    fi
fi

# Create n8n directory
echo -e "${YELLOW}Creating n8n directory...${NC}"
mkdir -p ~/n8n-compose
cd ~/n8n-compose

# Create necessary directories
mkdir -p local-files postgresql/docker-entrypoint-initdb.d

# Copy configuration files
echo -e "${YELLOW}Copying configuration files...${NC}"
cp "$(dirname "$0")/docker-compose.yml" ./
cp "$(dirname "$0")/.env" ./
cp "$(dirname "$0")/postgresql/docker-entrypoint-initdb.d/init-non-root-user.sh" ./postgresql/docker-entrypoint-initdb.d/

# Set permissions for PostgreSQL init script
chmod +x ./postgresql/docker-entrypoint-initdb.d/init-non-root-user.sh

# Ensure the network exists
echo -e "${YELLOW}Ensuring traefik-proxy network exists...${NC}"
docker network create traefik-proxy 2>/dev/null || true

# Start n8n
echo -e "${YELLOW}Starting n8n...${NC}"
docker compose up -d

# Success message
if [ -f ".env" ]; then
    SUBDOMAIN=$(grep "SUBDOMAIN" .env | cut -d '=' -f2)
    DOMAIN_NAME=$(grep "DOMAIN_NAME" .env | cut -d '=' -f2)
    echo -e "${GREEN}n8n installation completed!${NC}"
    echo -e "${GREEN}Your n8n instance will be available at: https://$SUBDOMAIN.$DOMAIN_NAME${NC}"
else
    echo -e "${GREEN}n8n installation completed!${NC}"
fi

echo -e "${YELLOW}Make sure you have set up DNS records for your domain.${NC}"

exit 0
