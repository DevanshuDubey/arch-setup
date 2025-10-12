#!/bin/bash
source ./interactive-config.sh

arch-chroot /mnt /bin/bash <<EOF
echo "=== Creating user $USERNAME ==="
useradd -m -G wheel -s /bin/bash $USERNAME

# Set user password from interactive input
echo "$USERNAME:$USERPASS" | chpasswd

echo "=== Configuring sudo ==="
# Allow wheel group members to use sudo
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
EOF
