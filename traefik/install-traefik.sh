#!/bin/bash

# ---------------------------------------------
# Traefik Reverse Proxy Installation
# ---------------------------------------------

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if a service is already using ports 80/443
echo -e "${YELLOW}Checking for existing services on ports 80/443...${NC}"
if docker ps | grep -q "0.0.0.0:80\|0.0.0.0:443\|:::80\|:::443"; then
    echo -e "${RED}A service is already using ports 80/443. Cannot install Traefik.${NC}"
    exit 1
fi

echo -e "${GREEN}Traefik installation started...${NC}"

# Create installation directory
echo -e "${YELLOW}Creating Traefik directory...${NC}"
mkdir -p ~/traefik-compose
cd ~/traefik-compose

# Create necessary directories
mkdir -p data

# Copy configuration files
echo -e "${YELLOW}Copying configuration files...${NC}"
cp "$(dirname "$0")/docker-compose.yml" ./
cp "$(dirname "$0")/.env" ./

# Create acme.json for Let's Encrypt certificates
touch data/acme.json
chmod 600 data/acme.json

# Create Docker network
echo -e "${YELLOW}Creating Docker network...${NC}"
docker network create traefik-proxy 2>/dev/null || true

# Start Traefik
echo -e "${YELLOW}Starting Traefik...${NC}"
docker compose up -d

# Success message
echo -e "${GREEN}Traefik installation completed!${NC}"
echo -e "${YELLOW}Traefik is now running as your reverse proxy.${NC}"
echo -e "${YELLOW}Other services can connect to the 'traefik-proxy' network.${NC}"

exit 0
