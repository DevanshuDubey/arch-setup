#!/bin/bash
set -euo pipefail

echo "=== Arch Installer Configuration ==="

prompt() {
    local var_name=$1
    local prompt_msg=$2
    read -rp "$prompt_msg: " input
    if [ -z "$input" ]; then
        echo "You must enter a value."
        exit 1
    fi
    eval $var_name="'$input'"
}

prompt DISK "Enter target disk (e.g., /dev/nvme0n1 or /dev/sda)"
prompt USERNAME "Enter your username"
prompt HOSTNAME "Enter your hostname"

read -rsp "Enter password for $USERNAME: " USERPASS; echo
read -rsp "Enter root password: " ROOTPASS; echo

[[ "$DISK" != /dev/* ]] && DISK="/dev/$DISK"

if [ ! -b "$DISK" ]; then
    echo "Disk $DISK not found!"
    exit 1
fi

read -rp "All data on $DISK will be erased. Continue? [y/N]: " CONFIRM
[[ $CONFIRM != "y" && $CONFIRM != "Y" ]] && echo "Aborted." && exit 0

echo "=== Partitioning $DISK ==="

parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart ROOT btrfs 513MiB 100%

if [[ "$DISK" =~ nvme ]]; then
    EFI_PART="${DISK}p1"
    ROOT_PART="${DISK}p2"
else
    EFI_PART="${DISK}1"
    ROOT_PART="${DISK}2"
fi

mkfs.fat -F32 "$EFI_PART"
mkfs.btrfs -f "$ROOT_PART"

echo "=== Creating BTRFS Subvolumes ==="
mount "$ROOT_PART" /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@snapshots

umount /mnt

echo "=== Mounting ==="
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ "$ROOT_PART" /mnt

mkdir -p /mnt/{home,var/log,var/cache/pacman/pkg,.snapshots,boot}

mount -o noatime,compress=zstd,space_cache=v2,subvol=@home "$ROOT_PART" /mnt/home
mount -o noatime,compress=zstd,space_cache=v2,subvol=@log "$ROOT_PART" /mnt/var/log
mount -o noatime,compress=zstd,space_cache=v2,subvol=@pkg "$ROOT_PART" /mnt/var/cache/pacman/pkg
mount -o noatime,compress=zstd,space_cache=v2,subvol=@snapshots "$ROOT_PART" /mnt/.snapshots

mount "$EFI_PART" /mnt/boot


echo "=== Installing Base System ==="
pacstrap -K /mnt \
    base linux linux-headers linux-firmware \
    amd-ucode btrfs-progs sudo \
    grub efibootmgr os-prober \
    networkmanager \
    nvidia nvidia-utils nvidia-dkms

genfstab -U /mnt >> /mnt/etc/fstab

echo "=== Configuring System ==="

arch-chroot /mnt /bin/bash <<EOF

ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "$HOSTNAME" > /etc/hostname
echo "127.0.1.1  $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

echo "root:$ROOTPASS" | chpasswd

useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$USERPASS" | chpasswd

sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

systemctl enable NetworkManager

echo "options nvidia_drm modeset=1" > /etc/modprobe.d/nvidia-kms.conf

ROOTUUID=\$(blkid -s UUID -o value $ROOT_PART)

sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nowatchdog loglevel=3 nvidia_drm.modeset=1 amd_pstate=active resume=UUID='"'\$ROOTUUID'"'"/' /etc/default/grub

echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "=== Creating 20G BTRFS Swapfile ==="
btrfs filesystem mkswapfile --size 20G --uuid clear /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

EOF

echo "=== Installation Complete! ==="
