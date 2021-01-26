#!/usr/bin/env bash

#TODO: Add a working solution for DISTDIR detection

Kernel_ZfsBuiltin_Unpack() {
  local global_distdir
  global_distdir="/var/cache/distfiles"
  einfo "Integrating ZFS Version ${ZFS_VERSION}"
  unpack "${global_distdir}/zfs-${ZFS_VERSION}.tar.gz"
}

Kernel_ZfsBuiltin_Configure() {
  einfo "Perparing Kernel for ZFS integration"
  mkdir "${WORKDIR}/prepare"
  restore_config "${S}/.config"
  if [ -e "${S}/.config" ]; then
    mv "${S}/.config" "${WORKDIR}/" || die
    cp "${WORKDIR}/.config" "${WORKDIR}/prepare/" || die
  fi

  local kern_arch
  kern_arch="$(tc-arch-kernel)"

  emake ARCH="${kern_arch}" O="${WORKDIR}/prepare" -C "${S}" defconfig || die
  emake ARCH="${kern_arch}" O="${WORKDIR}/prepare" -C "${S}" prepare || die
  cd "$HOME/zfs-${ZFS_VERSION}" || die

  einfo "Configuring ZFS"
  local zfs_config_opts=(
    --with-config=kernel
    --enable-linux-builtin
    --with-linux="${S}"
    --with-linux-obj="${WORKDIR}/prepare"
  )
  env ARCH="${kern_arch}" ./configure "${zfs_config_opts[@]}" || die

  einfo "Integrating ZFS into kernel source"
  env ARCH="${kern_arch}" ./copy-builtin "${S}" || die

  #Copy back config file
  if [ -e "${WORKDIR}/.config" ]; then
    mv "${WORKDIR}/.config" "${S}/" || die
  fi
  rm -r "${WORKDIR}/prepare" || die
}

Kernel_ZfsBuiltin_Postinst() {
  elog "===================================="
  elog "This kernel was installed with builtin ZFS sources."
}

if Kernel_IsOneOf gentoo-sources gentoo-kernel vanilla-sources vanilla-kernel; then
  ZFS_VERSION=$(pkg-config --modversion libzfs)
  BashrcdPhase unpack Kernel_ZfsBuiltin_Unpack
  BashrcdPhase configure Kernel_ZfsBuiltin_Configure
  BashrcdPhase postinst Kernel_ZfsBuiltin_Postinst
fi