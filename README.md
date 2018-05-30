# gentoo-ovh
OVH-specific Gentoo documentation and sources

This repo helps me keeping track of the configuration settings needed
to run Gentoo on a VPS 2016 SSD 1 at OVH.

## Links

* https://wiki.gentoo.org/wiki/User:MalakymR/Drafts/Gentoo_on_OVH_VPS
* https://wiki.gentoo.org/wiki/User:Flow/Gentoo_as_KVM_guest

## Recovery procedure in Rescue mode

```
cd /mnt
mkdir gentoo
mount /dev/vdb3 /mnt/gentoo
mount /dev/vdb1 /mnt/gentoo/boot
mount --rbind /proc /mnt/gentoo/proc
mount --rbind /dev /mnt/gentoo/dev
mount --rbind /sys /mnt/gentoo/sys
chroot /mnt/gentoo /bin/bash
source /etc/profile
mount -a

# edit kernel config and rebuild kernel
cd /usr/src/linux
make menuconfig
make
make modules_install
make install

# then unmount everything
umount -l /mnt/gentoo
```

Working kernel configuration file(s) could be found in the *etc*
directory.

## Install script

A (pseudo) installation script can be found in
*src/install-vps.sh*. This installation procedure applies to VPS SSD1
2016.