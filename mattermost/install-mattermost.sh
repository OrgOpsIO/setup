#!/bin/bash

# ---------------------------------------------
# Mattermost Docker-Compose Installation
# ---------------------------------------------

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the absolute path to the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}Mattermost installation started...${NC}"

# Check if Traefik is running
echo -e "${YELLOW}Checking for existing Traefik instance...${NC}"
if docker ps | grep -q "traefik"; then
    echo -e "${YELLOW}Traefik is running. Will connect to existing Traefik network.${NC}"
else
    echo -e "${YELLOW}Traefik is not running. It's recommended to install Traefik first.${NC}"
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
if [ -f "${SCRIPT_DIR}/docker-compose.yml" ] && [ -f "${SCRIPT_DIR}/.env" ]; then
    cp "${SCRIPT_DIR}/docker-compose.yml" ./
    cp "${SCRIPT_DIR}/.env" ./
else
    echo -e "${RED}Configuration files not found in ${SCRIPT_DIR}${NC}"
    echo -e "${RED}Make sure docker-compose.yml and .env exist in the same directory as this script.${NC}"
    exit 1
fi

# Set permissions
echo -e "${YELLOW}Setting permissions...${NC}"
sudo chown -R 999:999 volumes/postgres 2>/dev/null || echo -e "${YELLOW}Could not set permissions. This might be an issue on startup.${NC}"

# Ensure the network exists
echo -e "${YELLOW}Ensuring traefik-proxy network exists...${NC}"
docker network create traefik-proxy 2>/dev/null || true

# Start Mattermost
echo -e "${YELLOW}Starting Mattermost...${NC}"
docker compose up -d

# Verify Mattermost is running
if docker ps | grep -q "mattermost"; then
    # Get domain information from .env file
    if [ -f ".env" ]; then
        SUBDOMAIN=$(grep "SUBDOMAIN" .env | cut -d '=' -f2)
        DOMAIN_NAME=$(grep "DOMAIN_NAME" .env | cut -d '=' -f2)
        echo -e "${GREEN}Mattermost installation completed successfully!${NC}"
        echo -e "${GREEN}Your Mattermost instance will be available at: https://$SUBDOMAIN.$DOMAIN_NAME${NC}"
    else
        echo -e "${GREEN}Mattermost installation completed successfully!${NC}"
    fi
else
    echo -e "${RED}Something went wrong. Mattermost is not running.${NC}"
    echo -e "${YELLOW}Check the logs with: docker compose logs${NC}"
    exit 1
fi

echo -e "${YELLOW}Make sure you have set up DNS records for your domain.${NC}"

exit 0
