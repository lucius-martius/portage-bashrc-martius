#!/usr/bin/env bash


read -r -d '' INSTALLKERNEL_SCRIPT << 'EOF'
#!/usr/bin/env bash
exit 0
EOF

Kernel_NullInstall_Install() {
  cat <<< "${INSTALLKERNEL_SCRIPT}" > "${S}/installkernel"

  elog "===================================="
  elog "Replaced installkernel script with a noop script"
  elog "in order for gentoo-kernel to not install the"
  elog "image again during the postinst phase."
  elog "===================================="
}

if Kernel_IsOneOf installkernel-gentoo; then
  BashrcdPhase install Kernel_NullInstall_Install
fi