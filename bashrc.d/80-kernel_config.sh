#!/usr/bin/env bash

Kernel_Config_Configure(){
  einfo "Adding a config script to work directory"
  local scriptfile="${WORKDIR}/make.sh"
  echo "#!/usr/bin/env bash" > "${scriptfile}"
  echo "make O=${WORKDIR}/build -C ${S} \${1}" > "${scriptfile}"
  chmod +x "${scriptfile}" || die
}

Kernel_Config_Compile(){
  sed_cmd="s|CONFIG_LOCALVERSION=\".*\"|CONFIG_LOCALVERSION=\"-${PN%-kernel}\"|"
  sed -i -e "${sed_cmd}" "${WORKDIR}/build/.config" || die

  #reflect the fixed localversion
  KV_LOCALVERSION="-${PN%-kernel}"

  #TODO: Add microcode setting
}

if Kernel_IsOneOf gentoo-kernel vanilla-kernel; then
  BashrcdPhase configure Kernel_Config_Configure
  BashrcdPhase compile Kernel_Config_Compile
fi