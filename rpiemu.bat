@echo off

rem ===== Set the MACHINE variable =====
rem Possible values:
rem	       raspi
rem	       raspi2
rem	       virt
rem        versatilepb
rem        vexpress-a9
set MACHINE=virt

rem ===== Set the DEVELOPMENT variable =====
rem Possible values:
rem        1 : Catch kernel from kernel build path
rem        0 : Catch kernel from MACHINE definitions
set DEVELOPMENT=0

rem ===== Set the append string =====
rem set APPEND=console=ttyAMA0 root=/dev/mmcblk0p2
set APPEND=console=tty1 root=PARTUUID=37665771-02 rootfstype=ext4 fsck.repair=yes rootwait

rem ===== Set the image details =====
rem set IMAGE=%USERPROFILE%\Desktop\2017-11-29-raspbian-stretch-lite.img
set IMAGE=%USERPROFILE%\Desktop\moode.img
set IMAGEFMT=raw

rem ===== Set the nographic option ======
rem Uncomment to disable graphic console
rem Remember to add console=ttyAMA0 to append
rem string in order to access to console.
set NOGRAPHIC=-nographic

rem ===== Set the kernel build path =====
set KERNEL_SOURCE_PATH=%USERPROFILE%\AppData\Local\Packages\CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc\LocalState\rootfs\home\emiliano\linux-4.9.66

rem ===== Additional QEMU Configs =====
set QEMU_PARAMETERS=%QEMU_PARAMETERS% -monitor telnet:127.0.0.1:5021,server,nowait
set QEMU_PARAMETERS=%QEMU_PARAMETERS% -usb -device usb-ehci
rem set QEMU_PARAMETERS=%QEMU_PARAMETERS% -device usb-storage,drive=usbdrive,removable=on,id=usbdevice -drive file=%USERPROFILE%\Desktop\USB.img,id=usbdrive,if=none,format=raw

rem ========================================

cd %~dp0

set KERNEL_PATH=

2>NUL call :CASE_%MACHINE%
IF ERRORLEVEL 1 CALL :DEFAULT_CASE

IF "%DEVELOPMENT%"=="1" (
	set KERNEL_PATH=%KERNEL_SOURCE_PATH%\arch\arm\boot\
	set KERNEL_IMAGE=zImage
)

IF DEFINED DTB_FILE (
	set DTB=-dtb %KERNEL_PATH%dts\%DTB_FILE%
)

IF %CPUS% GEQ 2 (
	set SMP=-smp %CPUS%
)

IF "%CTLDEVICE%"=="virtio-blk-device" (
	set STORAGESTRING=-device %CTLDEVICE%,drive=disk0 -drive file=%IMAGE%,if=%DISKDEVICE%,format=%IMAGEFMT%,id=disk0
) ELSE (
	set STORAGESTRING=-drive file=%IMAGE%,format=%IMAGEFMT%
)

IF "%NETDEVICE%"=="virtio-net-device" (
	set NETWORKSTRING=-device %NETDEVICE%,netdev=eth0 -netdev user,id=eth0,hostfwd=tcp::5022-:22,hostfwd=tcp::5080-:80
)

IF DEFINED NOGRAPHIC (
	set APPEND=%APPEND% console=ttyAMA0
)
set APPEND="%APPEND%"

set CMDLINE="%PROGRAMFILES%"\qemu\qemu-system-aarch64.exe -machine %MACHINE% -kernel %KERNEL_PATH%%KERNEL_IMAGE% %DTB% %SMP% -m %MEM% -serial stdio -append %APPEND% %STORAGESTRING% %NETWORKSTRING% %NOGRAPHIC% --no-reboot %QEMU_PARAMETERS%

echo ======== rpiqemu.bat ==========
echo.
echo Path:         "%~dp0"
echo Kernel image: "%KERNEL_IMAGE%"
echo DTB:          "%DTB%"
echo CPUs:         "%CPUS%"
echo Memory:       "%MEM%"
echo Image device: "%DISKDEVICE%"
echo Image:        "%IMAGE%"
echo Image format: "%IMAGEFMT%"
echo.
echo Command line:
echo %CMDLINE%
%CMDLINE%
echo.

pause
exit /B

:CASE_raspi
set KERNEL_IMAGE=linux-4.9.66-bcm2835
set DTB_FILE=bcm2835-rpi-b-rev2.dtb
set CPUS=1
set MEM=512
set CTLDEVICE=virtio-blk-device
set DISKDEVICE=none
set NETDEVICE=virtio-net-device
goto END_CASE

:CASE_raspi2
set KERNEL_IMAGE=linux-4.9.66-bcm2835
set DTB_FILE=bcm2836-rpi-2-b.dtb
set CPUS=4
set MEM=1024
set CTLDEVICE=virtio-blk-device
set DISKDEVICE=none
set NETDEVICE=virtio-net-device
goto END_CASE

:CASE_versatilepb
set KERNEL_IMAGE=linux-4.9.66-versatile
set DTB_FILE=versatile-pb.dtb
set CPUS=1
set MEM=256
set DISKDEVICE=sd
goto END_CASE

:CASE_vexpress-a9
set KERNEL_IMAGE=linux-4.9.66-vexpress
set DTB_FILE=vexpress-v2p-ca9.dtb
set CPUS=2
set MEM=1024
set CTLDEVICE=virtio-blk-device
set DISKDEVICE=none
set NETDEVICE=virtio-net-device
goto END_CASE

:CASE_virt
set KERNEL_IMAGE=zImage
set CPUS=2
set MEM=1024
set CTLDEVICE=virtio-blk-device
set DISKDEVICE=none
set NETDEVICE=virtio-net-device
goto END_CASE

:DEFAULT_CASE
ECHO "%MACHINE%" not supported
GOTO :EOF

:END_CASE
VER > NUL
GOTO :EOF
