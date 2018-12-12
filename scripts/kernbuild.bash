#!/bin/bash
QEMU_RPI_PATH=/mnt/c/Users/desimonie/Documents/git/qemu-rpi
SRC_PATH=${HOME}/rpi/linux
BOOT_PATH=${QEMU_RPI_PATH}/boot
MOD_PATH=${QEMU_RPI_PATH}/modules

function prepare {
    NTHREADS=$(echo $(nproc)/2+1 | bc)
    export MAKEFLAGS="-j${NTHREADS}"
    KERNEL_VER=$(cd ${SRC_PATH}; make kernelversion)
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
        make KBUILD_CFLAGS='-O3' ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcmrpi3_defconfig
        make KBUILD_CFLAGS='-O3' ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
        make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=${TMP_MOD_PATH} modules_install
        make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_DTBS_PATH=${BOOT_PATH} dtbs_install
        cp ${SRC_PATH}/arch/arm64/boot/Image.gz ${BOOT_PATH}/kernel8.img
        install
        ;;
    "raspi2")
        prepare
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2709_defconfig
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs
        cp ${SRC_PATH}/arch/arm/boot/zImage ${BOOT_PATH}/kernel7.img
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=${TMP_MOD_PATH} modules_install
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_DTBS_PATH=${BOOT_PATH} dtbs_install
        install
        ;;
    "raspi")
        prepare
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcmrpi_defconfig
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs
        cp ${SRC_PATH}/arch/arm/boot/zImage ${BOOT_PATH}/kernel.img
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=${TMP_MOD_PATH} modules_install
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_DTBS_PATH=${BOOT_PATH} dtbs_install
        install
        ;;
    *)
        echo "raspi3|raspi2|raspi"
        exit 0
        ;;
esac
cd -