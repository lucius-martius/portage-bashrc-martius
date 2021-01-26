#!/usr/bin/env bash

Kernel_Symlink_PostInstall(){
  local kern_arch="${ARCH/amd64/x86_64}"
  local kern_name="${PN%-kernel}"
  local kern_ver="${PV}"
  local kern_file="vmlinuz-${kern_ver}-${kern_name}-${kern_arch}"

  if [ -e "/boot/vmlinuz" ]; then
    elog "===================================="
    elog "Overriding symlink /boot/vmlinuz."
    elog "===================================="
  fi

  ln -sf "${kern_file}" "/boot/vmlinuz" || die
}

if Kernel_IsOneOf gentoo-kernel vanilla-kernel; then
  BashrcdPhase postinst Kernel_Symlink_PostInstall
fi
