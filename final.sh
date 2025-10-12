#!/bin/bash
set -euo pipefail

echo "=== Arch Installer Configuration ==="

# --- Prompt function ---
prompt() {
    local var_name=$1
    local prompt_msg=$2
    read -p "$prompt_msg: " input
    if [ -z "$input" ]; then
        echo "You must enter a value."
        exit 1
    fi
    eval $var_name="'$input'"
}

# --- User prompts ---
prompt DISK "Enter target disk (e.g., /dev/sdb or nvme0n1)"
prompt USERNAME "Enter your username"
prompt HOSTNAME "Enter your hostname"

read -sp "Enter password for $USERNAME: " USERPASS
echo
read -sp "Enter root password: " ROOTPASS
echo

# Ensure /dev/ prefix
[[ "$DISK" != /dev/* ]] && DISK="/dev/$DISK"

# Confirm disk exists
if [ ! -b "$DISK" ]; then
    echo "Disk $DISK not found!"
    exit 1
fi

# Warn before wiping
read -p "All data on $DISK will be erased. Continue? [y/N]: " CONFIRM
[[ $CONFIRM != "y" && $CONFIRM != "Y" ]] && echo "Aborted." && exit 0

echo "=== Configuration complete ==="
echo "DISK=$DISK"
echo "USERNAME=$USERNAME"
echo "HOSTNAME=$HOSTNAME"

# --- Partitioning ---
echo "=== Partitioning $DISK ==="

EFI_SIZE="500MiB"
ROOT_SIZE="100G"

# Create partitions
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB $EFI_SIZE
parted -s "$DISK" set 1 boot on
parted -s "$DISK" mkpart ROOT ext4 $EFI_SIZE $ROOT_SIZE
parted -s "$DISK" mkpart HOME ext4 $ROOT_SIZE 100%

# Detect NVMe vs SATA
if [[ "$DISK" =~ nvme ]]; then
    EFI_PART="${DISK}p1"
    ROOT_PART="${DISK}p2"
    HOME_PART="${DISK}p3"
else
    EFI_PART="${DISK}1"
    ROOT_PART="${DISK}2"
    HOME_PART="${DISK}3"
fi

# Format partitions
mkfs.fat -F32 "$EFI_PART"
mkfs.ext4 "$ROOT_PART"
mkfs.ext4 "$HOME_PART"

# Mount partitions
mount "$ROOT_PART" /mnt
mkdir -p /mnt/home
mount "$HOME_PART" /mnt/home
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot

lsblk

# --- Base system installation ---
echo "=== Installing base system ==="
pacstrap /mnt base linux linux-firmware linux-headers nano vim git sudo bash-completion kitty \
    networkmanager dhclient grub efibootmgr os-prober xorg-server xorg-xinit xorg-apps \
    mesa mesa-utils swaybg swaylock wayland-protocols polkit polkit-gnome \
    python python-pip ttf-dejavu ttf-liberation noto-fonts pulseaudio wireplumber \
    pulseaudio-alsa pavucontrol brightnessctl nautilus gnome-control-center tlp tar wl-clipboard

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# --- Chroot configuration ---
arch-chroot /mnt /bin/bash <<EOF
# Timezone
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

# Locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo "$HOSTNAME" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

# Root password
echo "root:$ROOTPASS" | chpasswd

# Create user
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$USERPASS" | chpasswd

# Sudo configuration
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Install GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Swapfile
SWAP_SIZE=4096
fallocate -l ${SWAP_SIZE}M /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

# Enable NetworkManager
systemctl enable NetworkManager
EOF

# --- Chaotic AUR + yay ---
arch-chroot /mnt /bin/bash <<EOF
# Import Chaotic key
pacman-key --recv-key 3056513887B78AEB --keyserver hkps://keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB

# Add repo
pacman -U --noconfirm https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst

# Enable repo
echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf

# Update
pacman -Syyu --noconfirm

# Install yay
pacman -S --noconfirm yay
EOF

echo "=== Installation complete! ==="
