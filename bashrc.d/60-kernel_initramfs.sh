#!/usr/bin/env bash

# Collects and outputs list of necessary binaries
# @param1[in] name of array with a list of commands
# @param2[out] name of array for a list of required binaries
Kernel_Initramfs_CollectLibs() {
  local REGEX1='^.+?.so\..+? => (.+) \(0x[0-9a-f]{16}\)'
  local REGEX2='^(.+?ld-linux.+?) \(0x[0-9a-f]{16}\)'
  local -n in_list=${1}
  local -n out_list=${2}
  local -a to_resolve
  local cur_item

  #resolve names in $PATH
  to_resolve=("${in_list[@]}")
  out_list=()
  for item in "${to_resolve[@]}"; do
    echo "Resolving ${item} to $(which "${item}")"
    out_list+=("$(which "${item}")")
  done

  #resolve linked libaries
  to_resolve=("${out_list[@]}")
  while [[ -n ${to_resolve[0]} ]]; do
    #pop front of list
    cur_item="${to_resolve[0]}"
    unset "to_resolve[0]"
    to_resolve=("${to_resolve[@]}")

    #parse ldd output
    while LFS="" read -r line; do
      if [[ ${line} =~ ${REGEX1} || ${line} =~ ${REGEX2} ]]; then
        local new_bin=true
        for bin in "${out_list[@]}"; do
          if [[ ${bin} = "${BASH_REMATCH[1]}" ]]; then
            new_bin=false
          fi
        done
        if $new_bin; then
          to_resolve+=("${BASH_REMATCH[1]}")
          out_list+=("${BASH_REMATCH[1]}")
        fi
      fi
    done <<< "$(ldd "${cur_item}" || die)"
  done

  echo "${out_list[@]}"
}

Kernel_Initramfs_Prepare() {
  local initrd_dir="${WORKDIR}/initramfs"
  local file_list="${initrd_dir}/file_list"
  mkdir -p "${initrd_dir}" || die
  touch "${file_list}" || die

  local intel_microcode_dir="/lib/firmware/intel-ucode"
  if [ -e "${intel_microcode_dir}" ]; then
    cat "${intel_microcode_dir}"/* > "${initrd_dir}/GenuineIntel.bin"
    echo "file /kernel/x86/microcode/GenuineIntel.bin ${initrd_dir}/GenuineIntel.bin 0644 0 0" >> "${file_list}"
  fi

  echo "dir /dev 0755 0 0"  >> "${file_list}"
  echo "nod /dev/console 0622 0 0 c 5 1" >> "${file_list}"
  echo "nod /dev/null    0622 0 0 c 1 3" >> "${file_list}"
  echo "nod /dev/tty     0622 0 0 c 5 0" >> "${file_list}"
  echo "nod /dev/tty0    0622 0 0 c 4 0" >> "${file_list}"
  echo "nod /dev/tty1    0622 0 0 c 4 1" >> "${file_list}"
  echo "nod /dev/urandom 0622 0 0 c 1 9" >> "${file_list}"
  echo "nod /dev/random  0622 0 0 c 1 8" >> "${file_list}"
  echo "nod /dev/zero    0622 0 0 c 1 5" >> "${file_list}"

  echo "dir /etc 0755 0 0" >> "${file_list}"
  printf "/usr/lib64\n/lib64\n" > "${initrd_dir}/ld.so.conf" || die
  echo "file /etc/ld.so.conf ${initrd_dir}/ld.so.conf 0644 0 0" >> "${file_list}"

  #TODO: Move this into the zfs_builtin file
  if [ -e "/etc/zfs/zpool.cache" ]; then
    echo "dir /etc/zfs 0755 0 0" >> "${file_list}"
    echo "file /etc/zfs/zpool.cache /etc/zfs/zpool.cache 0644 0 0" >> "${file_list}"
  fi

  #TODO: Get list of directories programmatically
  echo "dir /bin 0755 0 0" >> "${file_list}"
  echo "dir /sbin 0755 0 0" >> "${file_list}"
  echo "dir /usr 0755 0 0" >> "${file_list}"
  echo "dir /usr/bin 0755 0 0" >> "${file_list}"
  echo "dir /usr/sbin 0755 0 0" >> "${file_list}"
  echo "dir /lib64 0755 0 0" >> "${file_list}"
  echo "dir /usr/lib64 0755 0 0" >> "${file_list}"

  local -a bin_list
  bin_list=(busybox)

  #Only include ZFS binaries if they exist
  if which zfs; then
    bin_list+=(zfs zpool mount.zfs)
  fi

  Kernel_Initramfs_CollectLibs bin_list bin_list || die

  for f in "${bin_list[@]}"; do
    echo "file ${f} ${f} 0755 0 0" >> "${file_list}"
  done

  echo "slink /bin/sh $(which busybox) 0755 0 0" >> "${file_list}"

  echo "file /init /usr/share/initramfs.init 0755 0 0" >> "${file_list}"


  #TODO: Find true kb layout
#   echo "dir /usr/share 0755 0 0" >> "${file_list}"
#   echo "dir /usr/share/keymaps 0755 0 0" >> "${file_list}"
#   echo "dir /usr/share/keymaps/i386 0755 0 0" >> "${file_list}"
#   echo "dir /usr/share/keymaps/i386/qwertz 0755 0 0" >> "${file_list}"
  loadkeys -b "/usr/share/keymaps/i386/qwertz/de-latin1.map.gz" \
    > "${initrd_dir}/default.bmap" || die
  echo "file /usr/share/keymaps/default.bmap ${initrd_dir}/default.bmap 0644 0 0" >> "${file_list}"

  einfo "Initramfs will be generated with the following structure:"
  cat "${file_list}"
}

Kernel_Initramfs_Compile() {
  einfo "Setting INITRAMFS_SOURCE in config"

  sed_cmd="s|CONFIG_INITRAMFS_SOURCE=\".*\"|CONFIG_INITRAMFS_SOURCE=\"${WORKDIR}/initramfs/file_list\"|"
  sed -i -e "${sed_cmd}" "${WORKDIR}/build/.config" || die
}

Kernel_Initramfs_Postinst() {
  elog "===================================="
  elog "This kernel has a builtin initramfs."
  elog "Currently additionally to filesystems supported by the kernel"
  elog "it will allow to bot via ZFS."
  elog "To do so, add \"root=ZFS=<filesystem>\" to your kernel cmdline."
  elog "Also Booting a virtual-machine via 9P is supported."
  elog "To do so, add \"root=9P=<tag>\" to your kernel cmdline."
}

if Kernel_IsOneOf gentoo-kernel vanilla-kernel; then
  BashrcdPhase prepare Kernel_Initramfs_Prepare
  BashrcdPhase compile Kernel_Initramfs_Compile
  BashrcdPhase postinst Kernel_Initramfs_Postinst
fi
