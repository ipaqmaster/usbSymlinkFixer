#!/bin/bash
[ $UID -ne 0 ] && SUDO=sudo # Sudo if not root

_scriptPath=$(realpath $0)
_scriptRoot="$(dirname $(realpath $0))"
_scriptName="$(basename ${_scriptRoot})"


customSerials=($@)

udevRulesFile="/etc/udev/rules.d/99-${_scriptName}.rules"

echo "If you have a USB to SATA adapter or HDD Dock you would like to target and HAVE NOT PLUGGED IT IN THIS BOOT CYCLE"
echo "Please do so before continuing so this script can find and target its generic serial."

read -rp "Press Enter when ready..."
echo


echo "Scanning 'journalctl -t kernel' for generic usb storage device serials. Stand by..."
genericSerials=($(sudo journalctl -t kernel | grep -Ei 'kernel.*usb.*SerialNumber:.*(123456|ABCDEF)' | awk '{print $NF}' | sort -u))
echo

if [ ${#genericSerials[*]} -eq 0 ] && [ -z "${customSerials}" ]
then
  echo "Found no generic serials we can target. If you know of one please intentionally provide it as an argument to this script and we will install the udev rule for it".
  echo "Here is a list of USB device serials seen on the system since this boot:"
  sudo journalctl --boot |grep -Ei 'kernel.*usb.*SerialNumber:.*' | awk '{print $NF}' | sed 's/^/\t/g'
  echo
  echo "If you don't have access to the device right now you can try running this script again without --boot in the earlier check command to check all history."
  exit 1
fi


# Install the rules
echo "Found ${#genericSerials[*]} generic serials we can target with this tool: ${genericSerials[*]}"
echo ""

echo "# $(date)" | $SUDO tee -a "${udevRulesFile}"
for Serial in ${genericSerials[*]} ${customSerials[*]}
do
  if grep -qs "\"${Serial}\"" "${udevRulesFile}"
  then
    echo "Rule for ${Serial} already present in the rule file. Skipping."
  else
    echo "# Rule for Serial: ${genericSerial}" | $SUDO tee -a "${udevRulesFile}"
    echo "KERNEL==\"sd[a-z]\", ENV{DEVTYPE}==\"disk\", SUBSYSTEM==\"block\", ENV{ID_SERIAL_SHORT}==\"${Serial}\", RUN+=\"${_scriptRoot}/main --path %N\"" | $SUDO tee -a "${udevRulesFile}"
  fi
done

echo "Reloading udev rules with udevadm..."
${SUDO} udevadm control --reload-rules
