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
			CONFIG_VIRTIO_BLK \
			CONFIG_VIRTIO_RING "
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
        KBUILD_BUILD_TIMESTAMP='' make CC="${CC}" KCFLAGS="${CFLAGS}" EXTRAVERSION=${MAKE_EXTRAVERSION} ${IMAGE} modules || exit 1
        KBUILD_BUILD_TIMESTAMP='' make CC="${CC}" KCFLAGS="${CFLAGS}" EXTRAVERSION=${MAKE_EXTRAVERSION} INSTALL_MOD_PATH=${TMP_MOD_PATH} modules_install || exit 1
        if [ ${DTBS} -eq 1 ]
        then
            KBUILD_BUILD_TIMESTAMP='' make CC="${CC}" KCFLAGS="${CFLAGS}" EXTRAVERSION=${MAKE_EXTRAVERSION} dtbs || exit 1
            KBUILD_BUILD_TIMESTAMP='' make CC="${CC}" KCFLAGS="${CFLAGS}" EXTRAVERSION=${MAKE_EXTRAVERSION} INSTALL_DTBS_PATH=${BOOT_PATH} dtbs_install || exit 1
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
	MAKE_EXTRAVERSION=-virt-v7+
	CONFIG_ENABLE_FLAGS="CONFIG_MODVERSIONS "
        kbuild
        ;;
    "raspi3")
        ARCH=arm64
        KCONFIG=bcmrpi3_defconfig
        VIRTIOCFG=0
        DTBS=1
	MAKE_EXTRAVERSION=-v7+
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
        echo "virt|raspi3|raspi2|raspi"
        exit 0
        ;;
esac
cd ${SAVEPATH}
