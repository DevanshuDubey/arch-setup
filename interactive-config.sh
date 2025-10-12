#!/bin/bash

echo "=== Arch Installer Configuration ==="

# Prompt helper function with default
prompt_default() {
    local var_name=$1
    local prompt_msg=$2
    local default_val=$3
    read -p "$prompt_msg [$default_val]: " input
    eval $var_name="${input:-$default_val}"
}

# Disk selection
prompt_default DISK "Enter target disk (e.g., /dev/sdb)" "/dev/sdX"

# EFI partition size
prompt_default EFI_SIZE "Enter EFI partition size" "500M"

# Root partition size
prompt_default ROOT_SIZE "Enter root partition size" "100G"

# Home partition size (default = rest of disk)
HOME_SIZE="rest"

# Username
prompt_default USERNAME "Enter your username" "user"

# Hostname
prompt_default HOSTNAME "Enter your hostname" "archpc"

# Swap size in MB
prompt_default SWAP_SIZE "Enter swapfile size in MB" "4096"

# Locale
prompt_default LOCALE "Enter system locale" "en_US.UTF-8"

# Timezone
prompt_default TIMEZONE "Enter timezone (Region/City)" "Asia/Kolkata"

echo "=== Configuration complete ==="
echo "DISK=$DISK"
echo "EFI_SIZE=$EFI_SIZE"
echo "ROOT_SIZE=$ROOT_SIZE"
echo "USERNAME=$USERNAME"
echo "HOSTNAME=$HOSTNAME"
echo "SWAP_SIZE=$SWAP_SIZE MB"
echo "LOCALE=$LOCALE"
echo "TIMEZONE=$TIMEZONE"
