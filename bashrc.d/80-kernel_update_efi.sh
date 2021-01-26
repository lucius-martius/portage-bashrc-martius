#!/usr/bin/env bash

Kernel_Efi_UpdateEntry(){
  local kern_arch="${ARCH/amd64/x86_64}"
  local kern_name="${PN%-kernel}"
  local kern_ver="${PV}"
  local kern_file="vmlinuz-${kern_ver}-${kern_name}-${kern_arch}"

  local kern_exists=false
  if [ -e "/boot/${kern_file}" ]; then
    kern_exists=true
  fi

  local efi_regex="Boot([0-9]{4})\\* ${kern_name^} \\(${kern_ver//./\\.} ${kern_arch}\\)"
  local efi_entryexists=false
  local efi_entrynum="0000"
  local efi_list
  efi_list=$(efibootmgr) || die
  while read -r entry; do
    if [[ ${entry} =~ ${efi_regex} ]]; then
      efi_entryexists=true
      efi_entrynum="${BASH_REMATCH[1]}"
      break
    fi
  done <<< "${efi_list}"

  if [ $kern_exists = "true" ]; then
    if [ ${efi_entryexists} = "false" ]; then
      local bootpart_info
      bootpart_info=$(df -PTh /boot | tail -n+2 | tr -s ' ') || die

      local bootpart_fs
      bootpart_fs=$(cut -d' ' -f2 <<< "${bootpart_info}") || die
      einfo "bootpart_fs: ${bootpart_fs}"

      [ "${bootpart_fs}" = "vfat" ] || die

      local bootpart_dev
      bootpart_dev=$(cut -d' ' -f1 <<< "${bootpart_info}") || die
      einfo "bootpart_dev: ${bootpart_dev}"

      local bootpart_num
      shopt -s extglob
      bootpart_num=${bootpart_dev#${bootpart_dev%%+([0-9])}}
      einfo "bootpart_num: ${bootpart_num}"

      local bootdisk
      bootdisk="/dev/$(lsblk -no pkname "${bootpart_dev}")" || die
      einfo "bootdisk: ${bootdisk}"

      einfo "Adding EFI boot-entry."
      local efibootmgr_args=(-c 1 -p "${bootpart_num}" -d "${bootdisk}" -L "${kern_name^} (${kern_ver} ${kern_arch})" -l "\\${kern_file}")
      efibootmgr "${efibootmgr_args[@]}" || die "efibootmgr failed: efibootmgr ${efibootmgr_args[*]}"
    else
      einfo "EFI boot-entry already present; Nothing to do."
    fi
  elif [ ${efi_entryexists} = "true" ]; then
    einfo "Deleting EFI boot-entry."
    efibootmgr -b "${efi_entrynum}" -B || die
  else
    einfo "No EFI boot-entry to delete; Nothing to do."
  fi
}

if Kernel_IsOneOf gentoo-kernel vanilla-kernel; then
  BashrcdPhase postinst Kernel_Efi_UpdateEntry
  BashrcdPhase postrm Kernel_Efi_UpdateEntry
fi