#!/bin/bash
source ./interactive-config.sh

arch-chroot /mnt /bin/bash <<EOF
echo "=== Creating user $USERNAME ==="
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$USERNAME" | chpasswd

echo "=== Configuring sudo ==="
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
EOF
