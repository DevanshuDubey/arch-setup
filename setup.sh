#!/bin/bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Run as a normal user, not root."
    exit 1
fi

echo "=== Updating system ==="
sudo pacman -Syu --noconfirm

###############################################################################
### INSTALL yay
###############################################################################
sudo pacman -S --noconfirm --needed git base-devel

if [[ ! -d ~/yay ]]; then
  git clone https://aur.archlinux.org/yay.git ~/yay
fi

cd ~/yay
makepkg -si --noconfirm
cd ~

###############################################################################
### FILE MANAGER — NAUTILUS
###############################################################################
sudo pacman -S --noconfirm \
  nautilus gvfs gvfs-mtp gvfs-afc gvfs-smb file-roller

###############################################################################
### PIPEWIRE AUDIO
###############################################################################
sudo pacman -S --noconfirm \
  pipewire pipewire-alsa pipewire-pulse pipewire-jack \
  wireplumber pavucontrol

###############################################################################
### WEB BROWSER — BRAVE (AUR)
###############################################################################
yay -S --noconfirm brave-bin

###############################################################################
### VSCODE OFFICIAL (AUR)
###############################################################################
yay -S --noconfirm visual-studio-code-bin

###############################################################################
### POWER MANAGEMENT
###############################################################################
sudo pacman -S --noconfirm tlp powertop
sudo systemctl enable tlp
sudo systemctl mask systemd-rfkill.service
sudo systemctl mask systemd-rfkill.socket

echo "=== Post-install complete ==="
echo "You can now run your Nvidia setup script and Hyprland setup later."
