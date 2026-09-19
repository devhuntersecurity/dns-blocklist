#!/bin/bash
# ==============================================================================
# IDGuard DNS - Automated Unbound Deployment Script for Debian
# Description: Installs Unbound, sets up configuration, whitelist directories,
#              and initializes remote control keys.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Please run this script with sudo or as root!${NC}"
    exit 1
fi

echo -e "${BLUE}[1/6] Updating package lists and installing Unbound...${NC}"
apt-get update
apt-get install -y unbound dnsutils curl

echo -e "${BLUE}[2/6] Preparing Unbound configuration directories...${NC}"
mkdir -p /etc/unbound/unbound.conf.d/malware
mkdir -p /etc/unbound/unbound.conf.d/zzz-whitelist

# Create AllowIP files if they don't exist
touch /etc/unbound/AllowIP_v4.conf
touch /etc/unbound/AllowIP_v6.conf

echo -e "${BLUE}[3/6] Downloading latest root hints (root.zones)...${NC}"
curl -o /var/lib/unbound/root.hints https://www.internic.net/domain/named.root
chown unbound:unbound /var/lib/unbound/root.hints
chmod 644 /var/lib/unbound/root.hints

echo -e "${BLUE}[4/6] Copying configuration file...${NC}"
if [ -f "unbound.conf.example" ]; then
    cp unbound.conf.example /etc/unbound/unbound.conf
    echo -e "${GREEN}Configuration copied successfully from unbound.conf.example.${NC}"
else
    echo -e "${RED}[WARNING] unbound.conf.example not found in current directory! Please check your repo files.${NC}"
fi

echo -e "${BLUE}[5/6] Generating Unbound remote control keys...${NC}"
if [ ! -f "/etc/unbound/unbound_server.key" ]; then
    unbound-control-setup -n
else
    echo "Remote control keys already exist, skipping generation."
fi

echo -e "${BLUE}[6/6] Testing configuration syntax and restarting service...${NC}"
unbound-checkconf

systemctl enable unbound
systemctl restart unbound

echo -e "\n${GREEN}==================================================================${NC}"
echo -e "${GREEN} SUCCESS: IDGuard DNS Unbound Resolver is up and running!         ${NC}"
echo -e "${GREEN}==================================================================${NC}"
echo -e "Check status using: ${BLUE}sudo systemctl status unbound${NC}"
echo -e "Monitor stats using: ${BLUE}sudo unbound-control stats_noreset${NC}"
