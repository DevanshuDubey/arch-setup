#!/bin/bash
echo "=== Installing base system and important packages ==="

# Core system + firmware
pacstrap /mnt base linux linux-firmware linux-headers

# Editors & utilities
pacstrap /mnt nano vim git sudo bash-completion kitty

# Networking
pacstrap /mnt networkmanager dhclient

# Bootloader tools
pacstrap /mnt grub efibootmgr os-prober

# X11 / Hyprland dependencies
pacstrap /mnt xorg-server xorg-xinit xorg-apps \
    mesa mesa-utils \
    swaybg swaylock wayland-protocols \
    polkit polkit-gnome \
    python python-pip

# Optional: fonts and audio
pacstrap /mnt ttf-dejavu ttf-liberation noto-fonts \
    pulseaudio wireplumber pulseaudio-alsa pavucontrol

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "=== Base installation complete ==="
