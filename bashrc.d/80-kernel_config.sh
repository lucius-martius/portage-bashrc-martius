#!/usr/bin/env bash

Kernel_Config_Configure(){
  einfo "Adding a config script to work directory"
  local scriptfile="${WORKDIR}/make.sh"
  echo "#!/usr/bin/env bash" > "${scriptfile}"
  echo "make O=${WORKDIR}/build -C ${S} \${1}" >> "${scriptfile}"
  chmod +x "${scriptfile}" || die
}

if Kernel_IsOneOf gentoo-kernel vanilla-kernel; then
  BashrcdPhase configure Kernel_Config_Configure
fi
