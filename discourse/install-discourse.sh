#!/bin/bash

# ---------------------------------------------
# Discourse Docker-Compose Installation
# ---------------------------------------------

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the absolute path to the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}Discourse installation started...${NC}"

# Check if Traefik is running
echo -e "${YELLOW}Checking for existing Traefik instance...${NC}"
if docker ps | grep -q "traefik"; then
    echo -e "${YELLOW}Traefik is running. Will connect to existing Traefik network.${NC}"
else
    echo -e "${YELLOW}Traefik is not running. It's recommended to install Traefik first.${NC}"
    echo -e "${YELLOW}Do you want to continue anyway? (y/n)${NC}"
    read -r response
    if [[ "$response" != "y" && "$response" != "Y" ]]; then
        echo -e "${RED}Discourse installation aborted.${NC}"
        exit 1
    fi
fi

# Create Discourse directory
echo -e "${YELLOW}Creating Discourse directory...${NC}"
mkdir -p ~/discourse-compose
cd ~/discourse-compose

# Create directory structure
echo -e "${YELLOW}Creating directory structure...${NC}"
mkdir -p volumes/{postgres,redis,shared,plugins,public}

# Copy configuration files
echo -e "${YELLOW}Copying configuration files...${NC}"
if [ -f "${SCRIPT_DIR}/docker-compose.yml" ] && [ -f "${SCRIPT_DIR}/.env" ]; then
    cp "${SCRIPT_DIR}/docker-compose.yml" ./
    cp "${SCRIPT_DIR}/.env" ./
else
    echo -e "${RED}Configuration files not found in ${SCRIPT_DIR}${NC}"
    echo -e "${RED}Make sure docker-compose.yml and .env exist in the same directory as this script.${NC}"
    exit 1
fi

# Set correct permissions for volumes
echo -e "${YELLOW}Setting correct permissions for volumes...${NC}"
# PostgreSQL needs UID 999
sudo chown -R 999:999 volumes/postgres 2>/dev/null || echo -e "${YELLOW}Could not set postgres permissions. This might be an issue on startup.${NC}"
# Redis needs UID 999
sudo chown -R 999:999 volumes/redis 2>/dev/null || echo -e "${YELLOW}Could not set redis permissions. This might be an issue on startup.${NC}"
# Bitnami Discourse uses UID 1001
sudo chown -R 1001:1001 volumes/shared volumes/plugins volumes/public 2>/dev/null || echo -e "${YELLOW}Could not set discourse permissions. This might be an issue on startup.${NC}"

# Ensure the network exists
echo -e "${YELLOW}Ensuring traefik-proxy network exists...${NC}"
docker network create traefik-proxy 2>/dev/null || true

# Start Discourse
echo -e "${YELLOW}Starting Discourse...${NC}"
docker compose up -d

# Verify Discourse is starting
echo -e "${YELLOW}Discourse is starting up. This may take several minutes for the first run...${NC}"
echo -e "${YELLOW}Checking status...${NC}"

sleep 10 # Give initial containers time to start

if docker ps | grep -q "discourse"; then
    echo -e "${GREEN}Discourse containers are running!${NC}"
    # Get domain information from .env file
    if [ -f ".env" ]; then
        SUBDOMAIN=$(grep "SUBDOMAIN" .env | cut -d '=' -f2)
        DOMAIN_NAME=$(grep "DOMAIN_NAME" .env | cut -d '=' -f2)
        ADMIN_USERNAME=$(grep "ADMIN_USERNAME" .env | cut -d '=' -f2)
        echo -e "${GREEN}Discourse is starting and will be available at: https://$SUBDOMAIN.$DOMAIN_NAME${NC}"
        echo -e "${YELLOW}Initial startup may take 5-10 minutes while Discourse configures itself.${NC}"
        echo -e "${YELLOW}You can log in with username: $ADMIN_USERNAME and the password you set in .env${NC}"
    else
        echo -e "${GREEN}Discourse is starting!${NC}"
    fi
else
    echo -e "${RED}Something went wrong. Discourse containers are not running.${NC}"
    echo -e "${YELLOW}Check the logs with: docker compose logs${NC}"
    exit 1
fi

echo -e "${YELLOW}Make sure you have set up DNS records for your domain.${NC}"
echo -e "${YELLOW}Check installation progress with: docker compose logs -f discourse${NC}"

exit 0
