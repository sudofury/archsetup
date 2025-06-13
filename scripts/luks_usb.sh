#!/bin/bash

set -e

#-------------------------------------------------------------------------------
# This script can:
#  - create a single LUKS-encrypted partition that spans a chosen USB drive
#  - create linkers to an existing LUKS-encrypted partition for auto mounting: 
#    * in /etc/fstab
#    * in /etc/crypttab
#    * in /run/media/<user>
#-------------------------------------------------------------------------------

# Functions for output formatting and user interaction:

# Highlight the output.
YELLOW="\e[1;33m" && RED="\e[1;31m" && GREEN="\e[1;32m" && COLOR_OFF="\e[0m"
cprint() { echo -ne "${1}${2}${COLOR_OFF}"; }
msg() { cprint ${YELLOW} "${1}\n"; }
status() { cprint ${YELLOW} "${1} "; }
error() { cprint ${RED} "${1}\n"; }
success() { cprint ${GREEN} "${1}\n"; }

# Display instructions.
show_help() {
	msg     "\nUsage: ${0} [option...] {--create|--link|--help}\n"
	error   "WARNING! Do not run this script as a root!"
	echo -e "This script requires sudo rights, but should be run as a non-root user.\n"
	msg     "--create    creates a LUKS partition that spans the entire drive"
	echo    "            Required arguments: <drive> <label>"
	echo    "            Example: ${0} --create /dev/sda backup"
	echo    "            Hint: use 'lsblk' to list connected drives"
	msg     "--link      puts UUID-links to the LUKS-encrypted drive in system files"
	echo    "            (use when connecting a LUKS-drive to a computer for a first time)"
	msg     "--help      displays this help message\n"
	exit 1
}

#-------------------------------------------------------------------------------

# Show warning if run as a root.
if [ "$EUID" -eq 0 ]; then
	error   "Do not run this script as a root!"
	echo -e "This script requires sudo rights, but should be run as a non-root user."
	exit
fi

case "${1}" in
	--help) show_help && exit 0 ;;
	--create)
		DRIVE="${2}"
		LABEL="${3}"
		msg "Creating partition table..."
		# Unmount the drive
		! mountpoint -q "${DRIVE}" || sudo umount "${DRIVE}"
		# Create new partition using fdisk
		echo -e "g\nn\n1\n\nt\nlinux\nw\n" | sudo fdisk "${DRIVE}"
		msg "Creating LUKS-container..."
		sudo cryptsetup luksFormat \
			--cipher=aes-xts-plain64 --key-size=512 --verify-passphrase "${DRIVE}1"
		msg "Mounting LUKS-container..."	
		sudo cryptsetup open "${DRIVE}1" "${LABEL}"
		sudo mkfs.ext4 "/dev/mapper/${LABEL}"
		sudo cryptsetup close "${LABEL}"
		success "LUKS-encrypted drive created successfully!"
		exit 0
		;;
		--link)
		
		;;
		*) show_help && exit 0 ;;
	esac



exit 0
