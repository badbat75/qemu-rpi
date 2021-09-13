##############################################
## Specify what acceleration should be used
## Intel HAXM - https://github.com/intel/haxm/releases
#HW_ACCEL=-accel hax
## Microsoft Hyper-V
#HW_ACCEL=-accel whpx
## TCG - Default acceleration
#set HW_ACCEL=-accel tcg
## KVM
HW_ACCEL="-accel kvm"
##############################################

DISK0=arch/x86_64/native-hd.img
DISK1=arch/x86_64/data-hd.img
CDROM=arch/x86_64/virtio-win-0.1.196.iso
MACHINE_SPECS="-M q35 -smp 2 -m 6144 -device virtio-balloon-pci -device virtio-rng-pci -boot menu=on"

#MACHINE_STORAGE="$MACHINE_STORAGE -device usb-host,hostbus=2,hostaddr=3" 
MACHINE_STORAGE="$MACHINE_STORAGE -device nvme,drive=disk0,serial=disk0-1 -drive file=$DISK0,if=none,format=raw,id=disk0"
#MACHINE_STORAGE="$MACHINE_STORAGE -device virtio-blk-pci,drive=disk0 -drive file=$DISK0,if=none,format=raw,id=disk0"
#MACHINE_STORAGE="$MACHINE_STORAGE -device virtio-blk-pci,drive=disk1 -drive file=arch/x86_64/data-hd.img,if=none,format=raw,id=disk1"
MACHINE_STORAGE="$MACHINE_STORAGE -cdrom $CDROM"

MACHINE_NETWORK="-device virtio-net-pci,netdev=eth0 -netdev user,id=eth0,hostfwd=tcp::5022-:22,hostfwd=tcp::5080-:80"

MACHINE_USBDEVS="-usb -device usb-ehci -device usb-kbd -device usb-mouse"

#MACHINE_9PFS="-fsdev local,id=kmods,path=%USERPROFILE%\Documents\git\qemu-rpi\modules,security_model=none -device virtio-9p-pci,fsdev=kmods,mount_tag=fs_kmods"

#MACHINE_GRAPHICS="-vga std"
#MACHINE_GRAPHICS="-nographic"
#MACHINE_GRAPHICS="-device virtio-vga,virgl=on -display sdl,gl=on"
MACHINE_GRAPHICS="-device virtio-vga,virgl=on"

MACHINE_AUDIO="-device intel-hda -audiodev alsa,id=default"

#MACHINE_SERIAL="-serial stdio"
MACHINE_SERIAL="-serial telnet:127.0.0.1:5021,server,nowait"

#MACHINE_MONITOR="-monitor stdio"
MACHINE_MONITOR="-monitor telnet:127.0.0.1:5020,server,nowait"

echo "qemu-system-x86_64 $HW_ACCEL $MACHINE_SPECS $MACHINE_STORAGE $MACHINE_NETWORK $MACHINE_USBDEVS $MACHINE_9PFS $MACHINE_GRAPHICS $MACHINE_AUDIO $MACHINE_SERIAL $MACHINE_MONITOR"
sudo qemu-system-x86_64 $HW_ACCEL $MACHINE_SPECS $MACHINE_STORAGE $MACHINE_NETWORK $MACHINE_USBDEVS $MACHINE_9PFS $MACHINE_GRAPHICS $MACHINE_AUDIO $MACHINE_SERIAL $MACHINE_MONITOR
