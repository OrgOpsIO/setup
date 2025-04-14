#!/bin/bash

# -------------------------------------
# Modular Installation Script for Services
# -------------------------------------

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the absolute path to the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to display usage information
show_help() {
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  $0 [component]"
    echo
    echo -e "${BLUE}Components:${NC}"
    echo -e "  traefik      - Install only Traefik reverse proxy"
    echo -e "  n8n          - Install only n8n"
    echo -e "  mattermost   - Install only Mattermost"
    echo -e "  discourse    - Install only Discourse"
    echo -e "  all          - Install all components"
    echo -e "  help         - Show this help"
    echo
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  $0 traefik   - Install only Traefik"
    echo -e "  $0 all       - Install all components"
}

# Function to install Traefik
install_traefik() {
    echo -e "${YELLOW}Starting Traefik installation...${NC}"
    
    # Run the Traefik installation script
    if [ -f "${SCRIPT_DIR}/traefik/install-traefik.sh" ]; then
        chmod +x "${SCRIPT_DIR}/traefik/install-traefik.sh"
        "${SCRIPT_DIR}/traefik/install-traefik.sh"
        return $?
    else
        echo -e "${RED}Traefik installation script not found at ${SCRIPT_DIR}/traefik/install-traefik.sh${NC}"
        return 1
    fi
}

# Function to install n8n
install_n8n() {
    echo -e "${YELLOW}Starting n8n installation...${NC}"
    
    # Run the n8n installation script
    if [ -f "${SCRIPT_DIR}/n8n/install-n8n.sh" ]; then
        chmod +x "${SCRIPT_DIR}/n8n/install-n8n.sh"
        "${SCRIPT_DIR}/n8n/install-n8n.sh"
        return $?
    else
        echo -e "${RED}n8n installation script not found at ${SCRIPT_DIR}/n8n/install-n8n.sh${NC}"
        return 1
    fi
}

# Function to install Mattermost
install_mattermost() {
    echo -e "${YELLOW}Starting Mattermost installation...${NC}"
    
    # Run the Mattermost installation script
    if [ -f "${SCRIPT_DIR}/mattermost/install-mattermost.sh" ]; then
        chmod +x "${SCRIPT_DIR}/mattermost/install-mattermost.sh"
        "${SCRIPT_DIR}/mattermost/install-mattermost.sh"
        return $?
    else
        echo -e "${RED}Mattermost installation script not found at ${SCRIPT_DIR}/mattermost/install-mattermost.sh${NC}"
        return 1
    fi
}

# Function to install Discourse
install_discourse() {
    echo -e "${YELLOW}Starting Discourse installation...${NC}"
    
    # Run the Discourse installation script
    if [ -f "${SCRIPT_DIR}/discourse/install-discourse.sh" ]; then
        chmod +x "${SCRIPT_DIR}/discourse/install-discourse.sh"
        "${SCRIPT_DIR}/discourse/install-discourse.sh"
        return $?
    else
        echo -e "${RED}Discourse installation script not found at ${SCRIPT_DIR}/discourse/install-discourse.sh${NC}"
        return 1
    fi
}

# Function to install all components
install_all() {
    echo -e "${YELLOW}Installing all components...${NC}"
    
    install_traefik && \
    install_n8n && \
    install_mattermost && \
    install_discourse
    
    echo -e "${GREEN}All components installed!${NC}"
}

# Main script execution
case "$1" in
    traefik)
        install_traefik
        ;;
    n8n)
        install_n8n
        ;;
    mattermost)
        install_mattermost
        ;;
    discourse)
        install_discourse
        ;;
    all)
        install_all
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        echo -e "${RED}Error: No component specified.${NC}"
        show_help
        exit 1
        ;;
    *)
        echo -e "${RED}Unknown component: $1${NC}"
        show_help
        exit 1
        ;;
esac
