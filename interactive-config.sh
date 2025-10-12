#!/bin/bash

echo "=== Arch Installer Configuration ==="

prompt_default() {
    local var_name=$1
    local prompt_msg=$2
    local default_val=$3
    read -p "$prompt_msg [$default_val]: " input
    eval $var_name="${input:-$default_val}"
}

# Existing prompts...
prompt_default DISK "Enter target disk (e.g., /dev/sdb)" "/dev/sdX"
prompt_default EFI_SIZE "Enter EFI partition size" "500M"
prompt_default ROOT_SIZE "Enter root partition size" "100G"
prompt_default USERNAME "Enter your username" "user"
prompt_default HOSTNAME "Enter your hostname" "archpc"
prompt_default SWAP_SIZE "Enter swapfile size in MB" "4096"
prompt_default LOCALE "Enter system locale" "en_US.UTF-8"
prompt_default TIMEZONE "Enter timezone (Region/City)" "America/New_York"

# Prompt for user password (hidden input)
read -sp "Enter password for $USERNAME [default: user]: " USERPASS
echo
USERPASS=${USERPASS:-$USERNAME}   # Use username as default if nothing entered

echo "=== Configuration complete ==="
echo "DISK=$DISK"
echo "EFI_SIZE=$EFI_SIZE"
echo "ROOT_SIZE=$ROOT_SIZE"
echo "USERNAME=$USERNAME"
echo "HOSTNAME=$HOSTNAME"
echo "SWAP_SIZE=$SWAP_SIZE MB"
echo "LOCALE=$LOCALE"
echo "TIMEZONE=$TIMEZONE"
echo "USERPASS=********"
