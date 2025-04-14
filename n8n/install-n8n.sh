#!/bin/bash

# ---------------------------------------------
# n8n Docker-Compose Installation
# ---------------------------------------------

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the absolute path to the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}n8n installation started...${NC}"

# Check if Traefik is running
echo -e "${YELLOW}Checking for existing Traefik instance...${NC}"
if docker ps | grep -q "traefik"; then
    echo -e "${YELLOW}Traefik is running. Will connect to existing Traefik network.${NC}"
else
    echo -e "${YELLOW}Traefik is not running. It's recommended to install Traefik first.${NC}"
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
if [ -f "${SCRIPT_DIR}/docker-compose.yml" ] && [ -f "${SCRIPT_DIR}/.env" ]; then
    cp "${SCRIPT_DIR}/docker-compose.yml" ./
    cp "${SCRIPT_DIR}/.env" ./
    
    # Check for init script
    if [ -f "${SCRIPT_DIR}/postgresql/docker-entrypoint-initdb.d/init-non-root-user.sh" ]; then
        cp "${SCRIPT_DIR}/postgresql/docker-entrypoint-initdb.d/init-non-root-user.sh" ./postgresql/docker-entrypoint-initdb.d/
        chmod +x ./postgresql/docker-entrypoint-initdb.d/init-non-root-user.sh
    else
        echo -e "${RED}PostgreSQL init script not found.${NC}"
        echo -e "${YELLOW}Creating a default init script...${NC}"
        
        # Create a default init script
        cat > ./postgresql/docker-entrypoint-initdb.d/init-non-root-user.sh << 'EOSQL'
#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER $POSTGRES_NON_ROOT_USER WITH PASSWORD '$POSTGRES_NON_ROOT_PASSWORD';
    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_NON_ROOT_USER;
    GRANT ALL PRIVILEGES ON SCHEMA public TO $POSTGRES_NON_ROOT_USER;
EOSQL
EOSQL
        chmod +x ./postgresql/docker-entrypoint-initdb.d/init-non-root-user.sh
    fi
else
    echo -e "${RED}Configuration files not found in ${SCRIPT_DIR}${NC}"
    echo -e "${RED}Make sure docker-compose.yml and .env exist in the same directory as this script.${NC}"
    exit 1
fi

# Ensure the network exists
echo -e "${YELLOW}Ensuring traefik-proxy network exists...${NC}"
docker network create traefik-proxy 2>/dev/null || true

# Start n8n
echo -e "${YELLOW}Starting n8n...${NC}"
docker compose up -d

# Verify n8n is running
if docker ps | grep -q "n8n"; then
    # Get domain information from .env file
    if [ -f ".env" ]; then
        SUBDOMAIN=$(grep "SUBDOMAIN" .env | cut -d '=' -f2)
        DOMAIN_NAME=$(grep "DOMAIN_NAME" .env | cut -d '=' -f2)
        echo -e "${GREEN}n8n installation completed successfully!${NC}"
        echo -e "${GREEN}Your n8n instance will be available at: https://$SUBDOMAIN.$DOMAIN_NAME${NC}"
    else
        echo -e "${GREEN}n8n installation completed successfully!${NC}"
    fi
else
    echo -e "${RED}Something went wrong. n8n is not running.${NC}"
    echo -e "${YELLOW}Check the logs with: docker compose logs${NC}"
    exit 1
fi

echo -e "${YELLOW}Make sure you have set up DNS records for your domain.${NC}"

exit 0
