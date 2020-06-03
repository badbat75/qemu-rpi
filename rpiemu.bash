#!/bin/bash

source rpiemu.conf

#===== Set the QEMUEXE variable =====
#Value is the path of the qemu-system-* executable
test -z "${QEMUEXE}" && QEMUEXE="qemu-system-aarch64"

#===== Set the MACHINE variable =====
#Possible values:
#	       raspi2
#	       raspi3
#	       virt
test -z ${MACHINE} && MACHINE="virt64"

test -z ${KVER} && KVER="5.4.44"

#===== Set the default IMAGE =====
test -z "${DEFIMAGE}" && DEFIMAGE="2020-02-05-raspbian-buster-lite.img"

#===== Set the DEVELOPMENT variable =====
#Possible values:
#       1 : Catch kernel from kernel build path
#       0 : Catch kernel from MACHINE definitions
DEVELOPMENT=0

#===== Set the append string =====
APPEND="rootfstype=ext4 fsck.repair=yes rootwait"

#===== Set the image details =====
#If passed thru batch parameter use it else it uses the DEFIMAGE one
if [ "x${1}" == "x" ]
then
	IMAGE=${DEFIMAGE}
else
	IMAGE=${1}
fi
IMAGEFMT=raw

#===== Set the nographic option ======
#Uncomment to disable graphic console
#Remember to add console=ttyAMA0 to append
#string in order to access to console.
#set NOGRAPHIC=-nographic

#===== Set Device Help ======
#If you want to list the devices can
#be configured set this
#set DEVICEHELP=1

#===== Set the kernel build path =====
#set KERNEL_SOURCE_PATH=${USERPROFILE}/AppData/Local/Packages/CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc/LocalState/rootfs/home/emiliano/linux-4.9.66

#===== Additional QEMU Configs =====
QEMU_PARAMETERS="${QEMU_PARAMETERS} -monitor telnet:127.0.0.1:5020,server,nowait"
QEMU_PARAMETERS="${QEMU_PARAMETERS} -usb -device usb-ehci -device usb-kbd -device usb-mouse"

#set QEMU_PARAMETERS=${QEMU_PARAMETERS} -device usb-storage,drive=usbdrive,removable=on,id=usbdevice -drive file=${USERPROFILE}/Desktop/USB.img,id=usbdrive,if=none,format=raw

#========================================

cd $(dirname $(realpath ${0}))

KERNEL_PATH=boot

case ${MACHINE} in
	raspi2)
		KERNEL_IMAGE=kernel7.img
		DTB_FILE=broadcom/bcm2709-rpi-2-b.dtb
		CPUS=4
		MEM=1024
		DISKDEVICE=sd
		NETDEVICE=usb-net
		#QEMU_PARAMETERS="${QEMU_PARAMETERS}"
		APPEND=${APPEND} root=/dev/mmcblk0p2
		#NOGRAPHIC=-nographic
	;;
	raspi3)
		KERNEL_IMAGE=kernel8.img
		DTB_FILE=broadcom/bcm2710-rpi-3-b-plus.dtb
		CPUS=4
		MEM=1024
		DISKDEVICE=sd
		NETDEVICE=usb-net
		SERIALDEVICE=usb-serial
		QEMU_PARAMETERS="${QEMU_PARAMETERS} -cpu cortex-a53"
		APPEND="${APPEND} root=/dev/mmcblk0p2"
		#NOGRAPHIC=-nographic
	;;
	virt)
		KERNEL_IMAGE=linux-${MACHINE}
		CPUS=2
		MEM=1024
		VIRTUALHW=1
		DISKDEVICE=sd
		QEMU_PARAMETERS="-device usb-ehci ${QEMU_PARAMETERS} -cpu cortex-a15 -soundhw hda -audiodev id=pa,driver=pa"
		APPEND="${APPEND} root=/dev/vda2"
		NOGRAPHIC=-nographic
		MACHINE=virt,highmem=off
	;;
	virt64)
		KERNEL_IMAGE=linux-${MACHINE}
		CPUS=2
		MEM=1024
		VIRTUALHW=1
		DISKDEVICE=sd
		QEMU_PARAMETERS="-device usb-ehci ${QEMU_PARAMETERS} -cpu cortex-a53 -soundhw hda -audiodev id=pa,driver=pa"
		APPEND="${APPEND} root=/dev/vda2"
		NOGRAPHIC=-nographic
		MACHINE=virt
	;;
	*)
		echo "${MACHINE}" not supported
		exit 1
	;;
esac

if [ ! -z ${DTB_FILE} ]
then
	DTB="-dtb ${KERNEL_PATH}/${KVER}/${DTB_FILE}"
fi

if [ "${CPUS}" -ge "2" ]
then
	SMP="-smp ${CPUS}"
fi

if [ "${VIRTUALHW}" == "1" ]; then
	# qemu-virt devices
	QEMU_PARAMETERS="-device qemu-xhci -device virtio-gpu-pci -vga std -device virtio-rng-pci ${QEMU_PARAMETERS}"
	CTLDEVICE=virtio-blk-device
	NETDEVICE=virtio-net-device
else
	#QEMU_PARAMETERS="-device usb-hub ${QEMU_PARAMETERS}"
fi

if [ "${CTLDEVICE}" == "virtio-blk-device" ]
then
	STORAGESTRING="-device ${CTLDEVICE},drive=disk0 -drive file=${IMAGE},if=${DISKDEVICE},format=${IMAGEFMT},id=disk0"
	#if [ -f cloud.img ]
	#then
	#	STORAGESTRING="-device ${CTLDEVICE},drive=cloud -drive file=cloud.img,if=none,format=raw,id=cloud ${STORAGESTRING} "
	#fi
else
	STORAGESTRING="-drive file=${IMAGE},if=${DISKDEVICE},format=${IMAGEFMT}"
fi

if [ ! -z ${NETDEVICE} ]
then
	NETWORKSTRING="-device ${NETDEVICE},netdev=eth0 -netdev user,id=eth0,hostfwd=tcp::5022-:22,hostfwd=tcp::5080-:80"
fi

if [ ! -z ${SERIALDEVICE} ]
then
	SERIALSTRING="-device ${SERIALDEVICE},chardev=ttyS0 -chardev socket,id=ttyS0,port=5021,host=0.0.0.0,nodelay,server,nowait,telnet"
else
	SERIALSTRING="-serial stdio"
fi

if [ ! -z ${NOGRAPHIC} ]
then
	APPEND="${APPEND} console=ttyAMA0,115200"
else
	APPEND="${APPEND} console=tty1"
fi
APPEND="${APPEND}"

BASECMD="${QEMUEXE} -machine ${MACHINE}"
RUNLINE="${BASECMD} -kernel ${KERNEL_PATH}/${KVER}/${KERNEL_IMAGE} ${DTB} ${SMP} -m ${MEM} -append "\"${APPEND}\"" ${STORAGESTRING} ${NETWORKSTRING} ${SERIALSTRING} ${NOGRAPHIC} --no-reboot ${QEMU_PARAMETERS}"
HELPLINE="${BASECMD} -device help"

echo ======== rpiqemu.bash ==========
echo
echo Path:         "${PWD}"
echo Kernel image: "${KERNEL_IMAGE}"
echo DTB:          "${DTB}"
echo CPUs:         "${CPUS}"
echo Memory:       "${MEM}"
echo Image device: "${DISKDEVICE}"
echo Image:        "${IMAGE}"
echo Image format: "${IMAGEFMT}"
echo
echo Command line:
if [ "${DEVICEHELP}" == "1" ]
then
	echo ${HELPLINE}
	eval ${HELPLINE}
else
	echo ${RUNLINE}
	eval ${RUNLINE}
fi
echo
