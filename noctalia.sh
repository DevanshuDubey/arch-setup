#!/bin/bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Do NOT run as root. Run as your normal user."
    exit 1
fi

echo "=== Updating system ==="
sudo pacman -Syu --noconfirm

echo "=== Installing Noctalia dependencies (AUR + repo) ==="

###############################################################################
### REQUIRED DEPENDENCIES
###############################################################################
yay -S --noconfirm quickshell gpu-screen-recorder brightnessctl

###############################################################################
### OPTIONAL (Highly recommended)
###############################################################################
yay -S --noconfirm cliphist matugen-git cava wlsunset xdg-desktop-portal python3 evolution-data-server

###############################################################################
### MONITOR BRIGHTNESS (May cause instability on some monitors)
###############################################################################
read -p "Install ddcutil (monitor brightness control)? [y/N]: " DDC
if [[ "$DDC" =~ ^[Yy]$ ]]; then
    yay -S --noconfirm ddcutil
fi

###############################################################################
### POLKIT AGENT (choose KDE agent unless user changes later)
###############################################################################
yay -S --noconfirm polkit-kde-agent

###############################################################################
### INSTALL NOCTALIA SHELL
###############################################################################
echo "=== Installing Noctalia Shell ==="

mkdir -p ~/.config/quickshell/noctalia-shell

curl -sL \
    https://github.com/noctalia-dev/noctalia-shell/releases/latest/download/noctalia-latest.tar.gz \
    | tar -xz --strip-components=1 -C ~/.config/quickshell/noctalia-shell

###############################################################################
### DONE
###############################################################################
echo
echo "==============================================="
echo " NOCTALIA INSTALLATION COMPLETE!"
echo " Launch with: quickshell"
echo " Config dir: ~/.config/quickshell/noctalia-shell"
echo "==============================================="
