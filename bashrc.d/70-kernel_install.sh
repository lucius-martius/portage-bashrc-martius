#!/usr/bin/env bash

Kernel_Install_Install() {
  local kern_arch="${ARCH/amd64/x86_64}"
  local kern_name="${PN%-kernel}"
  local kern_ver="${PV}"
  # shellcheck disable=SC2155
  local kern_path="${WORKDIR}/build/$(dist-kernel_get_image_path)"
  local kern_file="vmlinuz-${kern_ver}-${kern_name}-${kern_arch}"

  mount-boot_pkg_preinst

  exeinto "/boot"
  newexe "${kern_path}" "${kern_file}"
  rm "${kern_path}"
}

if Kernel_IsOneOf gentoo-kernel vanilla-kernel; then
  BashrcdPhase install Kernel_Install_Install
fi
