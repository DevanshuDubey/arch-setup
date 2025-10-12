#!/bin/bash
source ./interactive-config.sh

echo "=== Mounting partitions ==="
mount $ROOT_PART /mnt
mkdir -p /mnt/home
mount $HOME_PART /mnt/home
mkdir -p /mnt/boot
mount $EFI_PART /mnt/boot

lsblk
