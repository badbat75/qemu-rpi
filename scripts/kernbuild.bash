#!/bin/bash

[ -f kernbuild.conf ] && source kernbuild.conf

QEMU_RPI_PATH=${QEMU_RPI_PATH:-${HOME}/rpi/qemu-rpi}
SRC_PATH=${SRC_PATH:-${HOME}/rpi/linux}

SAVEPATH=${PWD}
TARGET=${1}

function prepare {
	[ ! -d ${BOOT_PATH} ] && mkdir -p ${BOOT_PATH}
	[ ! -d ${MOD_PATH} ] && mkdir -p ${MOD_PATH}
	test -d "${TMP_MOD_PATH}" && rm -rf ${TMP_MOD_PATH}
	mkdir -p ${TMP_MOD_PATH}
	test -f "${MOD_PATH}/linux-${KERNEL_VER}.tar.xz" && tar xJf ${MOD_PATH}/linux-${KERNEL_VER}.tar.xz -C${TMP_MOD_PATH}
	make clean
}

function install {
	cd ${TMP_MOD_PATH}
	tar cf - --owner=0 --group=0 . | xz -T0 > ${MOD_PATH}/linux-${KERNEL_VER}.tar.xz
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
			export CROSS_COMPILE_COMPAT=arm-linux-gnueabihf-
			IMAGE=Image
			;;
	esac
	TGTIMAGE=${SRC_PATH}/arch/${ARCH}/boot/${IMAGE}
	prepare
	KBUILD_BUILD_TIMESTAMP='' make CC="${CC:-${CROSS_COMPILE}gcc}" KCFLAGS="${CFLAGS}" EXTRAVERSION=${MAKE_EXTRAVERSION} ${KCONFIG} .config || exit 1
	if [ ${VIRTIOCFG} -eq 1 ]
		then
		# VirtIO Devices
		CONFIG_ENABLE_FLAGS+="CONFIG_VIRTIO \
			CONFIG_VIRTIO_NET \
			CONFIG_VIRTIO_PCI \
			CONFIG_VIRTIO_BALLOON \
			CONFIG_VIRTIO_INPUT \
			CONFIG_VIRTIO_BLK \
			CONFIG_VIRTIO_RING \
			CONFIG_DRM_VIRTIO_GPU \
			CONFIG_HW_RANDOM \
			CONFIG_HW_RANDOM_VIRTIO \
			CONFIG_SCSI_VIRTIO \
			CONFIG_VIRT_DRIVERS \
			CONFIG_FW_CFG_SYSFS \
			CONFIG_FW_CFG_SYSFS_CMDLINE "
		# Virtualization
		CONFIG_DISABLE_FLAGS+="CONFIG_VIRTUALIZATION "
		# Drivers/Graphics
		CONFIG_ENABLE_FLAGS+="CONFIG_DRM \
			CONFIG_DRM_QXL \
			CONFIG_DRM_BOCHS \
			CONFIG_FB_SIMPLE "
		CONFIG_DISABLE_FLAGS+="CONFIG_DRM_DEBUG_MM \
			CONFIG_LCD_CLASS_DEVICE \
			CONFIG_BACKLIGHT_CLASS_DEVICE \
			CONFIG_DRM_LEGACY "
		# XEN
		CONFIG_DISABLE_FLAGS+="CONFIG_XEN "
	fi
	case "${TARGET}" in
		"virt")
			CONFIG_ENABLE_FLAGS+="CONFIG_PCI \
				CONFIG_PCIEPORTBUS \
				CONFIG_PCI_MSI \
				CONFIG_PCI_HOST_GENERIC "
			#CONFIG_DISABLE_FLAGS+="CONFIG_ARCH_VEXPRESS "
		;;
		"virt64")
			# Platform selection
			CONFIG_DISABLE_FLAGS+="\
				CONFIG_ARCH_AGILEX \
				CONFIG_ARCH_SUNXI \
				CONFIG_ARCH_ALPINE \
				CONFIG_ARCH_BCM2835 \
				CONFIG_ARCH_BCM_IPROC \
				CONFIG_ARCH_BERLIN \
				CONFIG_ARCH_BRCMSTB \
				CONFIG_ARCH_EXYNOS \
				CONFIG_ARCH_K3 \
				CONFIG_ARCH_LAYERSCAPE \
				CONFIG_ARCH_LG1K \
				CONFIG_ARCH_HISI \
				CONFIG_ARCH_MEDIATEK \
				CONFIG_ARCH_MESON \
				CONFIG_ARCH_MVEBU \
				CONFIG_ARCH_MXC \
				CONFIG_ARCH_QCOM \
				CONFIG_ARCH_RENESAS \
				CONFIG_ARCH_ROCKCHIP \
				CONFIG_ARCH_SEATTLE \
				CONFIG_ARCH_STRATIX10 \
				CONFIG_ARCH_SYNQUACER \
				CONFIG_ARCH_TEGRA \
				CONFIG_ARCH_SPRD \
				CONFIG_ARCH_THUNDER \
				CONFIG_ARCH_THUNDER2 \
				CONFIG_ARCH_UNIPHIER \
				CONFIG_ARCH_VEXPRESS \
				CONFIG_ARCH_XGENE \
				CONFIG_ARCH_ZX \
				CONFIG_ARCH_ZYNQMP "
			# PCI controller drivers
			CONFIG_DISABLE_FLAGS+="CONFIG_PCI_AARDVARK \
				CONFIG_PCI_TEGRA \
				CONFIG_PCIE_RCAR \
				CONFIG_PCI_XGENE \
				CONFIG_PCIE_IPROC_PLATFORM \
				CONFIG_PCIE_ALTERA \
				CONFIG_PCI_HOST_THUNDER_PEM \
				CONFIG_PCI_HOST_THUNDER_ECAM \
				CONFIG_PCIE_ROCKCHIP_HOST \
				CONFIG_PCI_KEYSTONE_HOST \
				CONFIG_PCI_LAYERSCAPE \
				CONFIG_PCI_HISI \
				CONFIG_PCIE_QCOM \
				CONFIG_PCIE_ARMADA_8K \
				CONFIG_PCIE_KIRIN \
				CONFIG_PCIE_HISI_STB "
			# BUS
			CONFIG_DISABLE_FLAGS+="CONFIG_BRCMSTB_GISB_ARB \
				CONFIG_VEXPRESS_CONFIG "
			# Drivers/Graphics
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
				CONFIG_DRM_I2C_CH7006 \
				CONFIG_DRM_I2C_SIL164 \
				CONFIG_DRM_I2C_NXP_TDA998X \
				"
			# SCSI
			CONFIG_DISABLE_FLAGS+="CONFIG_SCSI_HISI_SAS \
				CONFIG_SCSI_MPT3SAS "
			# SATA
			CONFIG_DISABLE_FLAGS+="CONFIG_AHCI_CEVA \
				CONFIG_AHCI_XGENE \
				CONFIG_AHCI_QORIQ \
				CONFIG_SATA_SIL24 "
			# Ethernet
			CONFIG_DISABLE_FLAGS+="CONFIG_NET_VENDOR_3COM \
				CONFIG_NET_VENDOR_ADAPTEC \
				CONFIG_NET_VENDOR_AGERE \
				CONFIG_NET_VENDOR_ALACRITECH \
				CONFIG_NET_VENDOR_ALTEON \
				CONFIG_NET_VENDOR_AMAZON \
				CONFIG_NET_VENDOR_AMD \
				CONFIG_NET_VENDOR_AQUANTIA \
				CONFIG_NET_VENDOR_ARC \
				CONFIG_NET_VENDOR_ATHEROS \
				CONFIG_NET_VENDOR_AURORA \
				CONFIG_NET_VENDOR_BROADCOM \
				CONFIG_NET_VENDOR_BROCADE \
				CONFIG_NET_VENDOR_CADENCE \
				CONFIG_NET_VENDOR_CAVIUM \
				CONFIG_NET_VENDOR_CHELSIO \
				CONFIG_NET_VENDOR_CISCO \
				CONFIG_NET_VENDOR_CORTINA \
				CONFIG_NET_VENDOR_DEC \
				CONFIG_NET_VENDOR_DLINK \
				CONFIG_NET_VENDOR_EMULEX \
				CONFIG_NET_VENDOR_EZCHIP \
				CONFIG_NET_VENDOR_GOOGLE \
				CONFIG_NET_VENDOR_HISILICON \
				CONFIG_NET_VENDOR_HP \
				CONFIG_NET_VENDOR_HUAWEI \
				CONFIG_NET_VENDOR_I825XX \
				CONFIG_NET_VENDOR_MARVELL \
				CONFIG_NET_VENDOR_MELLANOX \
				CONFIG_NET_VENDOR_MICREL \
				CONFIG_NET_VENDOR_MICROCHIP \
				CONFIG_NET_VENDOR_MICROSEMI \
				CONFIG_NET_VENDOR_MYRI \
				CONFIG_NET_VENDOR_NATSEMI \
				CONFIG_NET_VENDOR_NETERION \
				CONFIG_NET_VENDOR_NETRONOME \
				CONFIG_NET_VENDOR_NI \
				CONFIG_NET_VENDOR_NVIDIA \
				CONFIG_NET_VENDOR_OKI \
				CONFIG_NET_VENDOR_PACKET_ENGINES \
				CONFIG_NET_VENDOR_QLOGIC \
				CONFIG_NET_VENDOR_QUALCOMM \
				CONFIG_NET_VENDOR_RDC \
				CONFIG_NET_VENDOR_REALTEK \
				CONFIG_NET_VENDOR_RENESAS \
				CONFIG_NET_VENDOR_ROCKER \
				CONFIG_NET_VENDOR_SAMSUNG \
				CONFIG_NET_VENDOR_SEEQ \
				CONFIG_NET_VENDOR_SOLARFLARE \
				CONFIG_NET_VENDOR_SILAN \
				CONFIG_NET_VENDOR_SIS \
				CONFIG_NET_VENDOR_SMSC \
				CONFIG_NET_VENDOR_SOCIONEXT \
				CONFIG_NET_VENDOR_STMICRO \
				CONFIG_NET_VENDOR_SUN \
				CONFIG_NET_VENDOR_SYNOPSYS \
				CONFIG_NET_VENDOR_TEHUTI \
				CONFIG_NET_VENDOR_TI \
				CONFIG_NET_VENDOR_VIA \
				CONFIG_NET_VENDOR_WIZNET "
			# Wireless LAN
			CONFIG_DISABLE_FLAGS+="CONFIG_WLAN_VENDOR_ADMTEK \
				CONFIG_WLAN_VENDOR_ATH \
				CONFIG_WLAN_VENDOR_ATMEL \
				CONFIG_WLAN_VENDOR_BROADCOM \
				CONFIG_WLAN_VENDOR_CISCO \
				CONFIG_WLAN_VENDOR_INTEL \
				CONFIG_WLAN_VENDOR_INTERSIL \
				CONFIG_WLAN_VENDOR_MARVELL \
				CONFIG_WLAN_VENDOR_MEDIATEK \
				CONFIG_WLAN_VENDOR_RALINK \
				CONFIG_WLAN_VENDOR_REALTEK \
				CONFIG_WLAN_VENDOR_RSI \
				CONFIG_WLAN_VENDOR_ST \
				CONFIG_WLAN_VENDOR_TI \
				CONFIG_WLAN_VENDOR_ZYDAS \
				CONFIG_WLAN_VENDOR_QUANTENNA "
			# USB LAN
			CONFIG_DISABLE_FLAGS+="CONFIG_USB_PEGASUS \
				CONFIG_USB_RTL8150 \
				CONFIG_USB_RTL8152 \
				CONFIG_USB_LAN78XX \
				CONFIG_USB_NET_AX8817X \
				CONFIG_USB_NET_AX88179_178A \
				CONFIG_USB_NET_DM9601 \
				CONFIG_USB_NET_SR9800 \
				CONFIG_USB_NET_SMSC75XX \
				CONFIG_USB_NET_SMSC95XX \
				CONFIG_USB_NET_NET1080 \
				CONFIG_USB_NET_PLUSB \
				CONFIG_USB_NET_MCS7830 \
				CONFIG_USB_BELKIN \
				CONFIG_USB_ARMLINUX \
				CONFIG_USB_NET_ZAURUS "
			# Audio
			CONFIG_DISABLE_FLAGS+="CONFIG_SND_HDA_TEGRA \
				CONFIG_SND_HDA_CODEC_HDMI \
				CONFIG_SND_BCM2835_SOC_I2S \
				CONFIG_SND_SOC_ROCKCHIP \
				CONFIG_SND_SOC_SAMSUNG \
				CONFIG_SND_SOC_AK4613 \
				CONFIG_SND_SOC_ES7134 \
				CONFIG_SND_SOC_ES7241 \
				CONFIG_SND_SOC_MAX98357A \
				CONFIG_SND_SOC_PCM3168A_I2C \
				CONFIG_SND_SOC_TAS571X "
			CONFIG_MODULE_FLAGS+="CONFIG_SND_INTEL8X0 \
				CONFIG_SND_HDA_INTEL \
				CONFIG_SND_HDA_GENERIC \
				CONFIG_SND_SOC_AC97_CODEC "
			CONFIG_ENABLE_FLAGS+="CONFIG_SND_HDA_HWDEP \
				CONFIG_SND_HDA_RECONFIG \
				CONFIG_SND_HDA_INPUT_BEEP \
				CONFIG_SND_HDA_PATCH_LOADER "
			# Touch Screen
			CONFIG_DISABLE_FLAGS+="CONFIG_TOUCHSCREEN_ATMEL_MXT "
			# Serial
			CONFIG_DISABLE_FLAGS+="CONFIG_SERIAL_8250_DW \
				CONFIG_SERIAL_XILINX_PS_UART \
				CONFIG_SERIAL_FSL_LPUART "
			# TPM
			CONFIG_DISABLE_FLAGS+="CONFIG_TCG_TPM "
			# I2C
			CONFIG_DISABLE_FLAGS+="CONFIG_I2C_MUX_PCA954x \
				CONFIG_I2C_DESIGNWARE_PLATFORM \
				CONFIG_I2C_RK3X "
			# SPI
			CONFIG_DISABLE_FLAGS+="CONFIG_SPI_NXP_FLEXSPI \
				CONFIG_SPI_PL022 \
				CONFIG_SPI_ROCKCHIP "
			# PIN Controller
			CONFIG_DISABLE_FLAGS+="CONFIG_PINCTRL_MAX77620 "
			# GPIO
			CONFIG_DISABLE_FLAGS+="CONFIG_GPIO_DWAPB \
				CONFIG_GPIO_MB86S7X \
				CONFIG_GPIO_MAX732X \
				CONFIG_GPIO_PCA953X \
				CONFIG_GPIO_MAX77620 "
			# Power Misc
			CONFIG_DISABLE_FLAGS+="CONFIG_POWER_RESET \
				CONFIG_POWER_SUPPLY "
			# HW Monitoring
			CONFIG_DISABLE_FLAGS+="CONFIG_HWMON	"
			# Voltage and Current Regulator
			CONFIG_DISABLE_FLAGS+="CONFIG_REGULATOR	"
			# MFD
			CONFIG_DISABLE_FLAGS+="CONFIG_MFD_BD9571MWV \
				CONFIG_MFD_AXP20X_I2C \
				CONFIG_MFD_HI6421_PMIC \
				CONFIG_MFD_MAX77620 \
				CONFIG_MFD_RK808 \
				CONFIG_MFD_SEC_CORE \
				CONFIG_MFD_ROHM_BD718XX "
			# Remote controller
			CONFIG_DISABLE_FLAGS+="CONFIG_RC_CORE "
			# HID
			CONFIG_DISABLE_FLAGS+="CONFIG_HID_A4TECH \
				CONFIG_HID_APPLE \
				CONFIG_HID_BELKIN \
				CONFIG_HID_CHERRY \
				CONFIG_HID_CHICONY \
				CONFIG_HID_CYPRESS \
				CONFIG_HID_EZKEY \
				CONFIG_HID_ITE \
				CONFIG_HID_KENSINGTON \
				CONFIG_HID_LOGITECH \
				CONFIG_HID_REDRAGON \
				CONFIG_HID_MICROSOFT \
				CONFIG_HID_MONTEREY "
			# USB
			CONFIG_DISABLE_FLAGS+="CONFIG_USB_MUSB_HDRC \
				CONFIG_USB_DWC3 \
				CONFIG_USB_DWC2 \
				CONFIG_USB_CHIPIDEA \
				CONFIG_USB_ISP1760 \
				CONFIG_USB_HSIC_USB3503 "
			# LEDS
			CONFIG_DISABLE_FLAGS+="CONFIG_NEW_LEDS "
			# MMC/SDCARD
			CONFIG_DISABLE_FLAGS+="CONFIG_MMC_ARMMMCI \
				CONFIG_MMC_SDHCI_PLTFM \
				CONFIG_MMC_DW "
			# RTC
			CONFIG_DISABLE_FLAGS+="CONFIG_RTC_DRV_MAX77686 \
				CONFIG_RTC_DRV_RK808 \
				CONFIG_RTC_DRV_RX8581 \
				CONFIG_RTC_DRV_S5M \
				CONFIG_RTC_DRV_DS3232 \
				CONFIG_RTC_DRV_CROS_EC \
				CONFIG_RTC_DRV_PL031 \
				CONFIG_RTC_DRV_SNVS "
			# DMA Engine
			CONFIG_DISABLE_FLAGS+="CONFIG_BCM_SBA_RAID \
				CONFIG_FSL_EDMA \
				CONFIG_MV_XOR_V2 \
				CONFIG_PL330_DMA \
				CONFIG_QCOM_HIDMA_MGMT \
				CONFIG_QCOM_HIDMA "
			# Chrome
			CONFIG_DISABLE_FLAGS+="CONFIG_CHROME_PLATFORMS \
				CONFIG_CROS_EC_I2C \
				CONFIG_CROS_EC_SPI \
				CONFIG_CROS_EC_LIGHTBAR \
				CONFIG_CROS_EC_VBC \
				CONFIG_CROS_EC_DEBUGFS \
				CONFIG_CROS_EC_SYSFS \
				CONFIG_KEYBOARD_CROS_EC \
				CONFIG_I2C_CROS_EC_TUNNEL \
				CONFIG_MFD_CROS_EC \
				CONFIG_MFD_CROS_EC_CHARDEV \
				CONFIG_CROS_EC_PROTO \
				CONFIG_EXTCON_USBC_CROS_EC "
			# Rpmsg
			CONFIG_DISABLE_FLAGS+="CONFIG_RPMSG_QCOM_GLINK_RPM "
			# SOC
			CONFIG_DISABLE_FLAGS+="CONFIG_SOC_BRCMSTB \
				CONFIG_SOC_TI "
			# IIO
			CONFIG_DISABLE_FLAGS+="CONFIG_IIO "
			# PWM
			CONFIG_DISABLE_FLAGS+="CONFIG_PWM_CROS_EC "
			# PMU
			CONFIG_DISABLE_FLAGS+="CONFIG_HISI_PMU "
			# PHY
			CONFIG_DISABLE_FLAGS+="CONFIG_PHY_XGENE \
				CONFIG_PHY_FSL_IMX8MQ_USB \
				CONFIG_PHY_QCOM_USB_HS "
			# FPGA
			CONFIG_DISABLE_FLAGS+="CONFIG_ALTERA_FREEZE_BRIDGE "
		;;
		"raspi3")
			# Drivers/USB
			#CONFIG_ENABLE_FLAGS+="CONFIG_USB_CATC \
			#	CONFIG_USB_CDC_PHONET \
			#	CONFIG_USB_HSO \
			#	CONFIG_USB_IPHETH \
			#	CONFIG_USB_KAWETH \
			#	CONFIG_USB_NET_CDC_SUBSET \
			#	CONFIG_USB_PEGASUS \
			à	CONFIG_USB_RTL8150 \
			#	CONFIG_USB_USBNET \
			#	CONFIG_USB_ZD1201 "
		;;
	esac
	
	if [ ${ENABLELTO:-0} -eq 1 ]
	then
		CONFIG_ENABLE_FLAGS+="CONFIG_LTO "
	fi

	for item in ${CONFIG_DISABLE_FLAGS}
	do
		scripts/config --disable ${item}
		echo "${item}: Disabled"
	done
	for item in ${CONFIG_MODULE_FLAGS}
	do
		scripts/config --module ${item}
		echo "${item}: Module"
	done
	for item in ${CONFIG_ENABLE_FLAGS}
	do
		scripts/config --enable ${item}
		echo "${item}: Enabled"
	done

	KBUILD_BUILD_TIMESTAMP='' make CC="${CC:-${CROSS_COMPILE}gcc}" KCFLAGS="${CFLAGS}" EXTRAVERSION=${MAKE_EXTRAVERSION} olddefconfig || exit 1
	KBUILD_BUILD_TIMESTAMP='' make CC="${CC:-${CROSS_COMPILE}gcc}" KCFLAGS="${CFLAGS}" EXTRAVERSION=${MAKE_EXTRAVERSION} ${IMAGE} modules || exit 1
	KBUILD_BUILD_TIMESTAMP='' make CC="${CC:-${CROSS_COMPILE}gcc}" KCFLAGS="${CFLAGS}" EXTRAVERSION=${MAKE_EXTRAVERSION} INSTALL_MOD_PATH=${TMP_MOD_PATH} modules_install || exit 1
	if [ ${DTBS} -eq 1 ]
	then
		KBUILD_BUILD_TIMESTAMP='' make CC="${CC:-${CROSS_COMPILE}gcc}" KCFLAGS="${CFLAGS}" EXTRAVERSION=${MAKE_EXTRAVERSION} dtbs || exit 1
		KBUILD_BUILD_TIMESTAMP='' make CC="${CC:-${CROSS_COMPILE}gcc}" KCFLAGS="${CFLAGS}" EXTRAVERSION=${MAKE_EXTRAVERSION} INSTALL_DTBS_PATH=${BOOT_PATH} dtbs_install || exit 1
	fi
	cp ${TGTIMAGE} ${BOOT_PATH}/${KNAME:-linux-${TARGET}}
	install
}

cd ${SRC_PATH}
NTHREADS=$(echo $(nproc)/2+1 | bc)
export MAKEFLAGS="-j${NTHREADS}"
KERNEL_VER=$(cd ${SRC_PATH}; make kernelversion) || exit 1
echo "Kernel version: ${KERNEL_VER}"
TMP_MOD_PATH=/tmp/linux-${KERNEL_VER}
BOOT_PATH=${QEMU_RPI_PATH}/${KERNEL_VER}/boot
MOD_PATH=${QEMU_RPI_PATH}/modules

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
		KNAME=kernel8.img
		kbuild
		;;
	"raspi2")
		ARCH=arm
		KCONFIG=bcm2709_defconfig
		VIRTIOCFG=0
		DTBS=1
		MAKE_EXTRAVERSION=-v7+
		KNAME=kernel7.img
		kbuild
		;;
	"raspi")
		ARCH=arm
		KCONFIG=bcmrpi_defconfig
		VIRTIOCFG=0
		DTBS=1
		MAKE_EXTRAVERSION=+
		KNAME=kernel.img
		kbuild
		;;    
	*)
		echo "virt|virt64|raspi3|raspi2|raspi"
		exit 0
		;;
esac

cd ${SAVEPATH}
