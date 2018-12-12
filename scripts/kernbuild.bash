#!/bin/bash
QEMU_RPI_PATH=${HOME}/rpi/qemu-rpi
SRC_PATH=${HOME}/rpi/linux
BOOT_PATH=${QEMU_RPI_PATH}/boot
MOD_PATH=${QEMU_RPI_PATH}/modules

function prepare {
    NTHREADS=$(echo $(nproc)/2+1 | bc)
    export MAKEFLAGS="-j${NTHREADS}"
    KERNEL_VER=$(cd ${SRC_PATH}; make kernelversion) || exit 1
    echo "Kernel version: ${KERNEL_VER}"
    TMP_MOD_PATH=/tmp/linux-${KERNEL_VER}
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

cd ${SRC_PATH}
case "${1}" in
    "raspi3")
        prepare
        make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcmrpi3_defconfig || exit 1
        make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- || exit 1
        make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=${TMP_MOD_PATH} modules_install || exit 1
        make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_DTBS_PATH=${BOOT_PATH} dtbs_install || exit 1
        cp ${SRC_PATH}/arch/arm64/boot/Image.gz ${BOOT_PATH}/kernel8.img
        install
        ;;
    "raspi2")
        prepare
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2709_defconfig || exit 1
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs || exit 1
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=${TMP_MOD_PATH} modules_install || exit 1
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_DTBS_PATH=${BOOT_PATH} dtbs_install || exit 1
        cp ${SRC_PATH}/arch/arm/boot/zImage ${BOOT_PATH}/kernel7.img
        install
        ;;
    "raspi")
        prepare
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcmrpi_defconfig || exit 1
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs || exit 1
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=${TMP_MOD_PATH} modules_install || exit 1
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_DTBS_PATH=${BOOT_PATH} dtbs_install || exit 1
        cp ${SRC_PATH}/arch/arm/boot/zImage ${BOOT_PATH}/kernel.img
        install
        ;;
    *)
        echo "raspi3|raspi2|raspi"
        exit 0
        ;;
esac
cd -