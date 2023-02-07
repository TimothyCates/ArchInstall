# Setup timezone and sync clock
ln -sf "/usr/share/zoneinfo/America/Phoenix"
hwclock --systohc

# Setup desired locales
sed -i "/en_US.UTF-8/s/^#//g" /etc/locale.conf
sed -i "/ja_JP.UTF-8/s/^#//g" /etc/locale.conf

locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Keymap
echo "KEYMAP=us" >> /etc/vconsole.conf

# Hosts
echo "arch" >> /etc/hostname

echo "127.0.0.1   localhost" >> /etc/hosts
echo "::1         localhost" >> /etc/hosts
echo "127.0.1.1   arch.localdomain arch" >> /etc/hosts

# Root Password
echo "root Pass:"
passwd

# User
echo "Username:"
read username
useradd --badname -m -g users -G wheel $username
clear

echo "Password:"
passwd $username

# Give wheel group sudo access
sed -i "s/^#\s*\(%wheel\s\+ALL=(ALL:ALL)\s\+ALL\)/\1/" /etc/sudoers

# Pacman config
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sed -i "/#Color/s/^#//" /etc/pacman.conf
mkdir -p /etc/pacman.d/hooks

# Bootloader
clear
source "refind.sh"

# Nvidia
yes | pacman -S nvidia-dkms nvidia-utils nvidia-settings lib32-nvidia-utils

# add early loading modules
sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/g' /etc/mkinitcpio.conf
mkinitcpio -P

mkdir -p /etc/modprobe.d/
touch /etc/modprobe.d/nvidia.conf
echo "options nvidia-drm modeset=1" >> /etc/modprobe.d/nvidia.conf

########################################################
# Install software (through pacman)
########################################################

yes | pacman -S networkmanager avahi iptables-nft openssh dnsmasq nfs-utils
yes | pacman -S rebuild-detector reflector
yes | pacman -S man-db ripgrep git jq bat exa fd fzf zsh

# We switched back to pulse audio, because its far easier to pass to a VM with single gpu passthrough
yes | pacman -S pulseaudio pulseaudio-alsa pulseaudio--bluetooth alsa-utils alsa-plugins pamixer

yes | pacman -S bluez
yes | pacman -S vivaldi vivaldi-ffmpeg-codecs libnotify lynx
yes | pacman -S xdg-user-dirs xdg-utils qbittorent
yes | pacman -S adobe-source-code-pro-conts cantarell-fonts ttf-opensans ttf-liberation

yes | pacman -S npm python-virtualenv
yes | pacman -S cups
yes | pacman -S discord steam
yes | pacman -S qemu-full virt-manager

# Enable libvirt group to access Unix docket ownership
sed -i "/#unix_sock_group/s/^#//" /etc/libvirt/libvirtd.conf
sed -i "/#unix_sock_rw_perms/s/^#//" /etc/libvirt/libvirtd.conf



########################################################
# Install Desktop Environment
########################################################
yes | pacman -S xclip xorg-server xorg-xsetroot xorg-xinit xorg-xinput numlockx
yes | pacman -S bspwm sxhkd


########################################################
# Add user to groups
########################################################
usermod -aG libvirt $username
usermod -aG lp $username


########################################################
# Enable systemd services
########################################################
systemctl enable libvirtd
systemctl enable NetworkManager
systemctl enable avahi-daemon
systemctl enable sshd
systemctl enable reflector.timer

# Run the user script
/bin/su -c "user.sh" -s /bin/bash $username
