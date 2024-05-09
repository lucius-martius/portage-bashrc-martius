#!/usr/bin/env bash

Kernel_Uninstall_Postrm(){
  local kern_arch="${ARCH/amd64/x86}"
  local kern_name="${PN%-kernel}"
  local kern_ver="${PV}"

  if [[ -e "/usr/src/linux-${kern_ver}-${kern_name}/arch/${kern_arch}/boot/bzImage" ]]; then
    einfo "Not removing anything because this is a rebuild"
  else
    local kern_moddir="/lib/modules/${kern_ver}-${kern_name}"
    if [[ -d "${kern_moddir}" ]]; then
      einfo "Removing ${kern_moddir}"
      rm -rdf "${kern_moddir}" || die
    fi

    while read -r file; do
      einfo "Removing ${file}"
      rm -f "${file}"
    done < <(find /boot -regex ".*${kern_ver}-${kern_name}\(.png\|.img\)?\(.old\)?")

    # shellcheck disable=SC2317
    function dist-kernel_compressed_module_cleanup () {
      echo "Not cleaning up modules."
    }
  fi
}

if Kernel_IsOneOf gentoo-kernel vanilla-kernel; then
  BashrcdPhase postrm Kernel_Uninstall_Postrm
fi
