#!/bin/bash

echo "=== Partitioning $DISK ==="

# Safety check
if [ ! -b "$DISK" ]; then
    echo "Disk $DISK not found!"
    exit 1
fi

# Wipe existing partitions (comment if not desired)
# sgdisk --zap-all $DISK

# Create GPT partitions
parted -s $DISK mklabel gpt
parted -s $DISK mkpart ESP fat32 1MiB $EFI_SIZE
parted -s $DISK set 1 boot on
parted -s $DISK mkpart ROOT ext4 $EFI_SIZE $ROOT_SIZE
parted -s $DISK mkpart HOME ext4 $ROOT_SIZE 100%

# Partition variables
EFI_PART="${DISK}p1"
ROOT_PART="${DISK}p2"
HOME_PART="${DISK}p3"

echo "=== Formatting partitions ==="
mkfs.fat -F32 $EFI_PART
mkfs.ext4 $ROOT_PART
mkfs.ext4 $HOME_PART
44