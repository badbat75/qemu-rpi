#!/bin/bash
QEMU_RPI_PATH=/mnt/c/Users/desimonie/Documents/git/qemu-rpi
SRC_PATH=${HOME}/rpi/linux
KERNEL_VER=$(cd ${SRC_PATH}; make kernelversion)
BOOT_PATH=${QEMU_RPI_PATH}/boot
MOD_PATH=${QEMU_RPI_PATH}/modules
TMP_MOD_PATH=/tmp/linux-${KERNEL_VER}

echo "Kernel version: ${KERNEL_VER}"

cd ${SRC_PATH}
make -j4 KBUILD_CFLAGS='-O3' ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcmrpi3_defconfig
make -j4 KBUILD_CFLAGS='-O3' ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
make -j4 KBUILD_CFLAGS='-O3' ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=${TMP_MOD_PATH} modules_install
make -j4 KBUILD_CFLAGS='-O3' ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_DTBS_PATH=${BOOT_PATH} dtbs_install
cp ${SRC_PATH}/arch/arm64/boot/Image.gz ${BOOT_PATH}/kernel8.img

make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2709_defconfig
make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs
make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=${TMP_MOD_PATH} modules_install
make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_DTBS_PATH=${BOOT_PATH} dtbs_install
cp ${SRC_PATH}/arch/arm/boot/zImage ${BOOT_PATH}/kernel7.img

make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcmrpi_defconfig
make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs
make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=${TMP_MOD_PATH} modules_install
make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_DTBS_PATH=${BOOT_PATH} dtbs_install
cp ${SRC_PATH}/arch/arm/boot/zImage ${BOOT_PATH}/kernel.img
cd -

cd ${TMP_MOD_PATH}
tar cf - . | xz -T0 > ${MOD_PATH}/linux-${KERNEL_VER}.tar.xz
cd -
rm -rf ${TMP_MOD_PATH}