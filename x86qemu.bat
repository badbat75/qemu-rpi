@echo off

set DISK0=arch/x86_64/native-hd.img
set DISK1=arch/x86_64/data-hd.img
set CDROM=arch/x86_64/ubuntu-19.10-live-server-amd64.iso

set MACHINE_SPECS=-smp 4 -m 6144

set MACHINE_STORAGE=-device virtio-blk-pci,drive=disk0 -drive file=%DISK0%,if=sd,format=raw,id=disk0
set MACHINE_STORAGE=%MACHINE_STORAGE% -device virtio-blk-pci,drive=disk1 -drive file=arch/x86_64/data-hd.img,if=sd,format=raw,id=disk1
set MACHINE_STORAGE=%MACHINE_STORAGE% -cdrom %CDROM%

set MACHINE_NETWORK=-device virtio-net-pci,netdev=eth0 -netdev user,id=eth0,hostfwd=tcp::5022-:22,hostfwd=tcp::5080-:80

set MACHINE_USBDEVS=-usb -device usb-ehci -device usb-kbd -device usb-mouse

rem set MACHINE_GRAPHICS=-vga std
set MACHINE_GRAPHICS=-nographic

set MACHINE_AUDIO=-device intel-hda -audiodev dsound,id=default

rem set MACHINE_SERIAL=-serial stdio
set MACHINE_SERIAL=-serial telnet:127.0.0.1:5021,server,nowait

rem set MACHINE_MONITOR=-monitor stdio
set MACHINE_MONITOR=-monitor telnet:127.0.0.1:5020,server,nowait

@echo on
"C:\Program Files"\qemu\qemu-system-x86_64.exe -accel hax %MACHINE_SPECS% %MACHINE_STORAGE% %MACHINE_NETWORK% %MACHINE_USBDEVS% %MACHINE_GRAPHICS% %MACHINE_AUDIO% %MACHINE_SERIAL% %MACHINE_MONITOR%
@echo off

pause