#!/usr/bin/env bash

Kernel_Uninstall_Postrm(){
  local kern_arch="${ARCH/amd64/x86_64}"
  local kern_name="${PN%-kernel}"
  local kern_ver="${PV}"
  local kern_file="vmlinuz-${kern_ver}-${kern_name}-${kern_arch}"

  if [ -e "/boot/${kern_file}" ]; then
    einfo "Not removing anything because this is a rebuild"
  else
    einfo "Removing /lib/modules/${kern_ver}-${kern_name}"
    rm -rdf "/lib/modules/${kern_ver}-${kern_name}" || die
  fi
}

if Kernel_IsOneOf gentoo-kernel vanilla-kernel; then
  BashrcdPhase postrm Kernel_Uninstall_Postrm
fi
