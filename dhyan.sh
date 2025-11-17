#!/bin/bash
set -euo pipefail

echo "=== Arch Installer Configuration ==="

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

# ------------------------------
# MANUAL PARTITION INPUT SECTION
# ------------------------------

prompt EFI_PART  "Enter EFI partition (e.g., /dev/sda1)"
prompt ROOT_PART "Enter ROOT partition (e.g., /dev/sda2)"
read -p "Enter HOME partition (optional, e.g., /dev/sda3): " HOME_PART

prompt USERNAME "Enter your username"
prompt HOSTNAME "Enter your hostname"

read -sp "Enter password for $USERNAME: " USERPASS
echo
read -sp "Enter root password: " ROOTPASS
echo

# Validate partitions
if [ ! -b "$EFI_PART" ] || [ ! -b "$ROOT_PART" ]; then
    echo "EFI or ROOT partition does not exist!"
    exit 1
fi

if [ -n "$HOME_PART" ] && [ ! -b "$HOME_PART" ]; then
    echo "HOME partition does not exist!"
    exit 1
fi

echo ""
echo "EFI_PART  = $EFI_PART"
echo "ROOT_PART = $ROOT_PART"
echo "HOME_PART = ${HOME_PART:-None}"
echo "USERNAME  = $USERNAME"
echo "HOSTNAME  = $HOSTNAME"
echo ""

read -p "WARNING: These partitions will be FORMATTED. Continue? [y/N]: " CONFIRM
[[ $CONFIRM != "y" && $CONFIRM != "Y" ]] && echo "Aborted." && exit 0


echo "=== Formatting partitions ==="
mkfs.fat -F32 "$EFI_PART"
mkfs.ext4 -F "$ROOT_PART"
[ -n "$HOME_PART" ] && mkfs.ext4 -F "$HOME_PART"

echo "=== Mounting partitions ==="
mount "$ROOT_PART" /mnt

if [ -n "$HOME_PART" ]; then
    mkdir -p /mnt/home
    mount "$HOME_PART" /mnt/home
fi

mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot

lsblk


# ------------------------------
# REST OF YOUR ORIGINAL SCRIPT
# ------------------------------

echo "=== Installing base system ==="
pacstrap /mnt base linux linux-firmware linux-headers nano vim git sudo bash-completion kitty \
    networkmanager dhclient grub efibootmgr os-prober xorg-server xorg-xinit xorg-apps \
    mesa mesa-utils swaybg swaylock wayland-protocols polkit polkit-gnome \
    python python-pip ttf-dejavu ttf-liberation noto-fonts pulseaudio wireplumber \
    pulseaudio-alsa pavucontrol brightnessctl nautilus gnome-control-center tlp tar wl-clipboard --noconfirm

genfstab -U /mnt >> /mnt/etc/fstab

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

# create mountpoint for swap (optional)
mkdir -p /swap
fallocate -l 16G /swap/swapfile
chmod 600 /swap/swapfile
mkswap /swap/swapfile
swapon /swap/swapfile

echo '/swap/swapfile none swap defaults 0 0' >> /etc/fstab

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
