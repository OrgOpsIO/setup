#!/bin/bash

# ---------------------------------------------
# Mattermost Docker-Compose Installation
# ---------------------------------------------

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Mattermost installation started...${NC}"

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
        echo -e "${RED}Mattermost installation aborted.${NC}"
        exit 1
    fi
fi

# Create Mattermost directory
echo -e "${YELLOW}Creating Mattermost directory...${NC}"
mkdir -p ~/mattermost-compose
cd ~/mattermost-compose

# Create directory structure
echo -e "${YELLOW}Creating directory structure...${NC}"
mkdir -p volumes/postgres volumes/data volumes/plugins volumes/client-plugins volumes/logs volumes/config

# Copy configuration files
echo -e "${YELLOW}Copying configuration files...${NC}"
cp "$(dirname "$0")/docker-compose.yml" ./
cp "$(dirname "$0")/.env" ./

# Set permissions
echo -e "${YELLOW}Setting permissions...${NC}"
# Ensure PostgreSQL directory has correct ownership
sudo chown -R 999:999 volumes/postgres || true

# Ensure the network exists
echo -e "${YELLOW}Ensuring traefik-proxy network exists...${NC}"
docker network create traefik-proxy 2>/dev/null || true

# Start Mattermost
echo -e "${YELLOW}Starting Mattermost...${NC}"
docker compose up -d

# Success message
if [ -f ".env" ]; then
    SUBDOMAIN=$(grep "SUBDOMAIN" .env | cut -d '=' -f2)
    DOMAIN_NAME=$(grep "DOMAIN_NAME" .env | cut -d '=' -f2)
    echo -e "${GREEN}Mattermost installation completed!${NC}"
    echo -e "${GREEN}Your Mattermost instance will be available at: https://$SUBDOMAIN.$DOMAIN_NAME${NC}"
else
    echo -e "${GREEN}Mattermost installation completed!${NC}"
fi

echo -e "${YELLOW}Make sure you have set up DNS records for your domain.${NC}"

exit 0
