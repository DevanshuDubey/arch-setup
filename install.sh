#!/bin/bash
chmod +x *.sh

./00-partition.sh
./01-mount.sh
./02-install-base.sh
./03-chroot-setup.sh
./04-user-setup.sh
./05-grub-swap.sh
./06-aur.sh


echo "=== Installation complete! You can reboot now ==="
umount -R /mnt

# Optional: pause 3 seconds before reboot
sleep 3

# Reboot automatically
reboot
