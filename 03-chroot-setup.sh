#!/bin/bash
source ./interactive-config.sh

# Prompt for root password
read -s -p "Enter root password: " ROOT_PASS
echo
read -s -p "Confirm root password: " ROOT_PASS_CONFIRM
echo

if [ "$ROOT_PASS" != "$ROOT_PASS_CONFIRM" ]; then
    echo "Passwords do not match! Exiting."
    exit 1
fi

arch-chroot /mnt /bin/bash <<EOF
echo "=== Setting timezone ==="
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

echo "=== Setting locale ==="
sed -i "s/#$LOCALE/$LOCALE/" /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

echo "=== Setting hostname ==="
echo "$HOSTNAME" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

echo "=== Setting root password ==="
echo "root:$ROOT_PASS" | chpasswd
EOF
