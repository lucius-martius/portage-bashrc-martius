#!/usr/bin/env bash

Kernel_IsOneOf() {
  for atom in "$@"; do
    if [ "${PN}" == "${atom}" ]; then
      return 0
    fi
  done
  return 1
}

Kernel_GetKernelFileName(){
  local kern_arch="${ARCH/amd64/x86_64}"
  local kern_name="${PN%-kernel}"
  local kern_ver="${PV}"

  echo "vmlinuz-${kern_ver}-${kern_name}-${kern_arch}"
}
