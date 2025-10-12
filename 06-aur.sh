#!/bin/bash


arch-chroot /mnt /bin/bash <<'EOF'
echo "=== Setting up Chaotic AUR ==="

# Import the Chaotic AUR key
sudo pacman-key --recv-key 3056513887B78AEB --keyserver hkps://keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB

# Add the Chaotic AUR repository
sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# Enable repository in pacman.conf
echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf

# Update package database
sudo pacman -Syyu --noconfirm

echo "=== Installing yay from Chaotic AUR ==="
sudo pacman -S --noconfirm yay
EOF
