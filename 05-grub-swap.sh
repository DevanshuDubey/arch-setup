#!/bin/bash

arch-chroot /mnt /bin/bash <<EOF
echo "=== Installing GRUB ==="
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "=== Creating swapfile ==="
fallocate -l ${SWAP_SIZE}M /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

echo "=== Enabling NetworkManager ==="
systemctl enable NetworkManager
EOF
