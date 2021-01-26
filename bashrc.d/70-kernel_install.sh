#!/usr/bin/env bash

Kernel_Install_Install() {
  local kern_arch="${ARCH/amd64/x86_64}"
  local kern_name="${PN%-kernel}"
  local kern_ver="${PV}"
  local kern_file="vmlinuz-${kern_ver}-${kern_name}-${kern_arch}"

  mount-boot_pkg_preinst

  exeinto "/boot"
  newexe "${WORKDIR}/build/$(dist-kernel_get_image_path)" "${kern_file}"
}

if Kernel_IsOneOf gentoo-kernel vanilla-kernel; then
  BashrcdPhase preinst Kernel_Install_Install
fi
