# Steps to install Gentoo on a VPS SSD1 2016 from OVH
# Source: https://wiki.gentoo.org/wiki/User:MalakymR/Drafts/Gentoo_on_OVH_VPS
# (with a few tweaks, such as a larger /boot partition, updated stage3 url,
# ovh gentoo mirror, typos).

# Prepare disk volumes
umount /mnt/vdb*
echo -e "o\nn\np\n1\n\n+128M\nn\np\n2\n\n+1024M\nn\np\n3\n\n\nt\n2\n82\na\n1\nw" | fdisk /dev/vdb
mkfs.ext2 /dev/vdb1
mkfs.ext4 /dev/vdb3
mkswap /dev/vdb2
swapon /dev/vdb2

# Install Gentoo stage 3
mkdir /mnt/gentoo
mount /dev/vdb3 /mnt/gentoo
cd /mnt/gentoo
wget http://gentoo.mirrors.ovh.net/gentoo-distfiles/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-20180529T214502Z.tar.xz
tar xvJpf stage3-*.tar.xz --xattrs --numeric-owner
rm stage3-*.tar.xz

# Initial configuration
echo 'MAKEOPTS="-j2"' >> /mnt/gentoo/etc/portage/make.conf
echo 'GENTOO_MIRRORS="rsync://ftp.halifax.rwth-aachen.de/gentoo/ ftp://gentoo.mirrors.ovh.net/gentoo-distfiles/ http://gentoo.mirrors.ovh.net/gentoo-distfiles/"' >> /mnt/gentoo/etc/portage/make.conf
sed -i s/CFLAGS=\"/CFLAGS=\"-march\=native\ /g /mnt/gentoo/etc/portage/make.conf
echo 'USE="-X -gtk -systemd -qt -gnome -kde -alsa -pulseaudio bash-completion"' >> /mnt/gentoo/etc/portage/make.conf
mkdir /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf

# Chroot to new environment
cp -L /etc/resolv.conf /mnt/gentoo/etc/
mount -t proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
chroot /mnt/gentoo /bin/bash 
source /etc/profile 
export PS1="(chroot) $PS1"

# Initial system sync
mount /dev/vdb1 /boot
emerge-webrsync
emerge --sync
emerge --update --deep --newuse --ask @world

# Regional settings
echo "Europe/Paris" > /etc/timezone
emerge --config sys-libs/timezone-data
echo 'en_US ISO-8859-1' >>  /etc/locale.gen
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen
echo 'LANG="en_US.utf8"' > /etc/env.d/02locale
env-update
source /etc/profile
export PS1="(chroot) $PS1"

# Configure and compile kernel
emerge sys-kernel/gentoo-sources --ask
cd /usr/src/linux
make menuconfig

# At that stage, enable the following features (built-in, not module)
# (as of 4.9.95)

# CONFIG_PARAVIRT=y
# CONFIG_HYPERVISOR_GUEST=y
# CONFIG_VIRTIO_PCI=y
# CONFIG_VIRTIO_BALLOON=y
# CONFIG_VIRTIO_MMIO=y
# CONFIG_VIRTIO_BLK=y
# CONFIG_SCSI_VIRTIO=y
# CONFIG_VIRTIO_NET=y
# CONFIG_VHOST_NET=y
# CONFIG_BLOK_DEV_RAM=y
# CONFIG_VIRT_DRIVERS=y
# CONFIG_EXT2_FS=y
# CONFIG_EXT2_FS_XATTR=y
# CONFIG_EXT2_FS_POSIX_ACL=y

# Additionally, set the following:
# General setup -> default hostname
# Remove Networking support -> Amateur Radio Support
# Remove Device Drivers -> Sound card support
# Remove X86 Platform Specific Device Drivers -> Eee PC Hotkey Driver

MAKEOPTS="-j2" make
make modules_install
make install

# Update fstab
# This should stay as vda even though we are currently mounted under vdb
echo '/dev/vda1   /boot        ext2    defaults,noatime     0 2' >> /etc/fstab
echo '/dev/vda2   none         swap    sw                   0 0' >> /etc/fstab
echo '/dev/vda3   /            ext4    noatime              0 1' >> /etc/fstab

# Configure networking
echo 'hostname="tux"' > /etc/conf.d/hostname
echo 'dns_domain_lo="0xd0.org"' >> /etc/conf.d/net
echo 'config_eth0="dhcp"' >> /etc/conf.d/net
cd /etc/init.d/
ln -s net.lo net.eth0
rc-update add net.eth0 default
sed -i s/localhost/tux.0xd0.org\ tux\ localhost/g /etc/hosts

# Additional tools
emerge syslog-ng cronie --ask
rc-update add syslog-ng default
rc-update add cronie default
rc-update add sshd default
sed -i s/#PermitRootLogin\ prohibit-password/PermitRootLogin\ yes/g /etc/ssh/sshd_config
emerge dhcpcd --ask

# Grub
emerge --verbose sys-boot/grub:2 --ask
grub-install /dev/vdb
grub-mkconfig -o /boot/grub/grub.cfg
sed -i s/vdb/vda/g /boot/grub/grub.cfg

# Set password and reboot (hopefully)
passwd
exit
cd
umount -l /mnt/gentoo
# and reboot from OVH panel
