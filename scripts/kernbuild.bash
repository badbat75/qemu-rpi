#!/bin/bash
QEMU_RPI_PATH=${HOME}/rpi/qemu-rpi
SRC_PATH=${HOME}/rpi/linux
BOOT_PATH=${QEMU_RPI_PATH}/boot
MOD_PATH=${QEMU_RPI_PATH}/modules

SAVEPATH=${PWD}
TARGET=${1}

function prepare {
	[ ! -d ${BOOT_PATH} ] && mkdir ${BOOT_PATH}
	[ ! -d ${MOD_PATH} ] && mkdir ${MOD_PATH}
	test -d "${TMP_MOD_PATH}" && rm -rf ${TMP_MOD_PATH}
	mkdir -p ${TMP_MOD_PATH}
	test -f "${MOD_PATH}/linux-${KERNEL_VER}.tar.xz" && tar xJf ${MOD_PATH}/linux-${KERNEL_VER}.tar.xz -C${TMP_MOD_PATH}
	make clean
}

function install {
	cd ${TMP_MOD_PATH}
	tar cf - . | xz -T0 > ${MOD_PATH}/linux-${KERNEL_VER}.tar.xz
	cd -
	rm -rf ${TMP_MOD_PATH}
}

function kbuild {
		export ARCH
		case ${ARCH} in
			arm)
				export CROSS_COMPILE=arm-linux-gnueabihf-
				IMAGE=zImage
				;;
			arm64)
				export CROSS_COMPILE=aarch64-linux-gnu-
				IMAGE=Image
				;;
		esac
		TGTIMAGE=${SRC_PATH}/arch/${ARCH}/boot/${IMAGE}
		prepare
		KBUILD_BUILD_TIMESTAMP='' make CC="${CC:-${CROSS_COMPILE}gcc}" KCFLAGS="${CFLAGS}" EXTRAVERSION=${MAKE_EXTRAVERSION} ${KCONFIG} .config || exit 1
	if [ ${VIRTIOCFG} -eq 1 ]
		then
		CONFIG_ENABLE_FLAGS+="CONFIG_VIRTIO \
			CONFIG_VIRTIO_NET \
			CONFIG_VIRTIO_PCI \
			CONFIG_VIRTIO_BALLOON \
			CONFIG_VIRTIO_INPUT \
			CONFIG_VIRTIO_BLK \
			CONFIG_VIRTIO_RING \
			CONFIG_DRM \
			CONFIG_DRM_CIRRUS_QEMU \
			CONFIG_DRM_QXL \
			CONFIG_DRM_BOCHS \
			CONFIG_DRM_VIRTIO_GPU "
		CONFIG_DISABLE_FLAGS+="CONFIG_DRM_DEBUG_MM \
			CONFIG_TEGRA_HOST1X \
			CONFIG_DRM_NOUVEAU \
			CONFIG_DRM_EXYNOS \
			CONFIG_DRM_ROCKCHIP \
			CONFIG_DRM_RCAR_DU \
			CONFIG_DRM_RCAR_LVDS \
			CONFIG_DRM_SUN4I \
			CONFIG_DRM_MSM \
			CONFIG_DRM_TEGRA \
			CONFIG_DRM_VC4 \
			CONFIG_DRM_HISI_HIBMC \
			CONFIG_DRM_HISI_KIRIN \
			CONFIG_DRM_MESON \
			CONFIG_DRM_PL111 \
			CONFIG_DRM_LIMA \
			CONFIG_DRM_PANFROST \
			CONFIG_DRM_SII902X \
			CONFIG_DRM_I2C_ADV7511 \
			CONFIG_FB_MX3 \
			CONFIG_LCD_CLASS_DEVICE \
			CONFIG_BACKLIGHT_CLASS_DEVICE \
			CONFIG_DRM_LEGACY"
	fi
	if [ ${TARGET} == "raspi3" ]
		then
		CONFIG_ENABLE_FLAGS+="CONFIG_USB_CATC \
			CONFIG_USB_CDC_PHONET \
			CONFIG_USB_HSO \
			CONFIG_USB_IPHETH \
			CONFIG_USB_KAWETH \
			CONFIG_USB_NET_CDC_SUBSET \
			CONFIG_USB_PEGASUS \
			CONFIG_USB_RTL8150 \
			CONFIG_USB_USBNET \
			CONFIG_USB_ZD1201 "
	fi
	
	if [ ${ENABLELTO:-0} -eq 1 ]
	then
		CONFIG_ENABLE_FLAGS+="CONFIG_LTO "
	fi
	for item in ${CONFIG_ENABLE_FLAGS}
	do
		scripts/config --enable ${item}
		echo "${item}: Enabled"
	done
	for item in ${CONFIG_DISABLE_FLAGS}
	do
		scripts/config --disable ${item}
		echo "${item}: Disabled"
	done
		KBUILD_BUILD_TIMESTAMP='' make CC="${CC:-${CROSS_COMPILE}gcc}" KCFLAGS="${CFLAGS}" EXTRAVERSION=${MAKE_EXTRAVERSION} ${IMAGE} modules || exit 1
		KBUILD_BUILD_TIMESTAMP='' make CC="${CC:-${CROSS_COMPILE}gcc}" KCFLAGS="${CFLAGS}" EXTRAVERSION=${MAKE_EXTRAVERSION} INSTALL_MOD_PATH=${TMP_MOD_PATH} modules_install || exit 1
		if [ ${DTBS} -eq 1 ]
		then
			KBUILD_BUILD_TIMESTAMP='' make CC="${CC:-${CROSS_COMPILE}gcc}" KCFLAGS="${CFLAGS}" EXTRAVERSION=${MAKE_EXTRAVERSION} dtbs || exit 1
			KBUILD_BUILD_TIMESTAMP='' make CC="${CC:-${CROSS_COMPILE}gcc}" KCFLAGS="${CFLAGS}" EXTRAVERSION=${MAKE_EXTRAVERSION} INSTALL_DTBS_PATH=${BOOT_PATH} dtbs_install || exit 1
		fi
		cp ${TGTIMAGE} ${BOOT_PATH}/${KNAME:-linux-${KERNEL_VER}-${TARGET}}
		install
}

cd ${SRC_PATH}
NTHREADS=$(echo $(nproc)/2+1 | bc)
export MAKEFLAGS="-j${NTHREADS}"
KERNEL_VER=$(cd ${SRC_PATH}; make kernelversion) || exit 1
echo "Kernel version: ${KERNEL_VER}"
TMP_MOD_PATH=/tmp/linux-${KERNEL_VER}

case "${TARGET}" in
	"virt")
		ARCH=arm
		KCONFIG=vexpress_defconfig
		VIRTIOCFG=1
		DTBS=0
		MAKE_EXTRAVERSION=-virt
		CONFIG_ENABLE_FLAGS="CONFIG_MODVERSIONS "
		kbuild
		;;
	"virt64")
		ARCH=arm64
		KCONFIG=defconfig
		VIRTIOCFG=1
		DTBS=0
		MAKE_EXTRAVERSION=-virt64
		CONFIG_ENABLE_FLAGS="CONFIG_MODVERSIONS "
		kbuild
		;;
	"raspi3")
		ARCH=arm64
		KCONFIG=bcmrpi3_defconfig
		VIRTIOCFG=0
		DTBS=1
		MAKE_EXTRAVERSION=-v8+
		KNAME=kernel8-${KERNEL_VER}.img
		kbuild
		;;
	"raspi2")
		ARCH=arm
		KCONFIG=bcm2709_defconfig
		VIRTIOCFG=0
		DTBS=1
		MAKE_EXTRAVERSION=-v7+
		KNAME=kernel7-${KERNEL_VER}.img
		kbuild
		;;
	"raspi")
		ARCH=arm
		KCONFIG=bcmrpi_defconfig
		VIRTIOCFG=0
		DTBS=1
	MAKE_EXTRAVERSION=+
		KNAME=kernel-${KERNEL_VER}.img
		kbuild
		;;    
	*)
		echo "virt|virt64|raspi3|raspi2|raspi"
		exit 0
		;;
esac
cd ${SAVEPATH}
