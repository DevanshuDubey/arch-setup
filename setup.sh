#!/bin/bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Run as normal user (not root)"
    exit 1
fi

echo "=== Updating System ==="
sudo pacman -Syu --noconfirm

###############################################################################
### CHAOTIC AUR
###############################################################################
echo "=== Adding Chaotic AUR ==="
sudo pacman-key --recv-key 3056513887B78AEB --keyserver hkps://keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB

sudo pacman -U --noconfirm \
    https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst \
    https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst

echo "[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf

sudo pacman -Syyu --noconfirm


###############################################################################
### INSTALL YAY (AUR helper)
###############################################################################
sudo pacman -S --noconfirm --needed git base-devel
git clone https://aur.archlinux.org/yay.git ~/yay || true
cd ~/yay
makepkg -si --noconfirm
cd ~


###############################################################################
### HYPRLAND + PIPEWIRE + UTILITIES
###############################################################################
sudo pacman -S --noconfirm \
  hyprland hyprpaper hyprlock waybar wlogout \
  kitty wl-clipboard grim slurp \
  xdg-desktop-portal xdg-desktop-portal-hyprland \
  network-manager-applet brightnessctl \
  pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber pavucontrol


###############################################################################
### FILE MANAGER: NAUTILUS
###############################################################################
sudo pacman -S --noconfirm \
  nautilus gvfs gvfs-mtp gvfs-afc gvfs-smb file-roller


###############################################################################
### BRAVE (Official binary)
###############################################################################
yay -S --noconfirm brave-bin


###############################################################################
### VSCode (Official Microsoft Build)
###############################################################################
yay -S --noconfirm visual-studio-code-bin


###############################################################################
### NVIDIA HYBRID OFFLOAD TOOL
###############################################################################
echo "=== Configuring Nvidia Hybrid ==="

sudo tee /etc/modprobe.d/nvidia-power.conf >/dev/null <<EOF
options nvidia NVreg_DynamicPowerManagement=0x02
EOF

mkdir -p ~/.local/bin

cat <<'EOF' > ~/.local/bin/nvrun
#!/bin/bash
__NV_PRIME_RENDER_OFFLOAD=1 \
__GLX_VENDOR_LIBRARY_NAME=nvidia \
__VK_LAYER_MESA_device_select=1 \
"$@"
EOF

chmod +x ~/.local/bin/nvrun


###############################################################################
### HYPRLAND CONFIG
###############################################################################
mkdir -p ~/.config/hypr ~/.config/hyprpaper ~/.config/waybar

cat <<'EOF' > ~/.config/hypr/hyprland.conf
exec-once=waybar &
exec-once=nm-applet &
exec-once=hyprpaper &
EOF

curl -sSL https://raw.githubusercontent.com/adi1090x/wallpapers/master/Minimal/17.jpg \
    -o ~/Pictures/default.jpg || true

echo "preload = ~/Pictures/default.jpg
wallpaper = , ~/Pictures/default.jpg" > ~/.config/hyprpaper.conf


###############################################################################
### POWER OPTIMIZATION
###############################################################################
sudo pacman -S --noconfirm tlp powertop
sudo systemctl enable tlp
sudo systemctl mask systemd-rfkill.service
sudo systemctl mask systemd-rfkill.socket

echo "=== POST INSTALL COMPLETE ==="
