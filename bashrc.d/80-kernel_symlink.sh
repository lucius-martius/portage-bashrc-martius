#!/usr/bin/env bash

Kernel_Symlink_PostInstall(){
  local kern_name="${PN%-kernel}"
  local kern_ver="${PV}"
  local kern_file="vmlinuz-${kern_ver}-${kern_name}"
  local initramfs_file="initramfs-${kern_ver}-${kern_name}.img"

  if [ -e "/boot/vmlinuz" ]; then
    elog "===================================="
    elog "Overriding symlink /boot/vmlinuz."
    elog "===================================="
  fi

  ln -sf "${kern_file}" "/boot/vmlinuz" || die

  if [ -e "/boot/initramfs" ]; then
    elog "===================================="
    elog "Overriding symlink /boot/initramfs."
    elog "===================================="
  fi

  if [ -e "${initramfs_file}" ]; then
    ln -sf "${initramfs_file}" "/boot/initramfs" || die
  fi
}

if Kernel_IsOneOf gentoo-kernel vanilla-kernel; then
  BashrcdPhase postinst Kernel_Symlink_PostInstall
fi
