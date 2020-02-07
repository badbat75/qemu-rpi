@echo off

rem ===== Set the MACHINE variable =====
rem Possible values:
rem	       raspi2
rem	       raspi3
rem	       virt
rem	       virt64
set MACHINE=virt

set KVER=5.5.2

rem ===== Set the default IMAGE =====
set DEFIMAGE=arch\armhfp\2019-09-26-raspbian-buster-lite.img

rem ===== Set the DEVELOPMENT variable =====
rem Possible values:
rem        1 : Catch kernel from kernel build path
rem        0 : Catch kernel from MACHINE definitions
set DEVELOPMENT=0

rem ===== Set the append string =====
set APPEND=rootfstype=ext4 fsck.repair=yes rootwait

rem ===== Set the image details =====
rem If passed thru batch parameter use it else it uses the DEFIMAGE one
IF "%~1"=="" (
set IMAGE=%DEFIMAGE%
) ELSE (
set IMAGE=%~1
)
set IMAGEFMT=raw

rem ===== Set the nographic option ======
rem Uncomment to disable graphic console
rem Remember to add console=ttyAMA0 to append
rem string in order to access to console.
rem set NOGRAPHIC=-nographic

rem ===== Set Device Help ======
rem If you want to list the devices can
rem be configured set this
rem set DEVICEHELP=1

rem ===== Set the kernel build path =====
rem set KERNEL_SOURCE_PATH=%USERPROFILE%\AppData\Local\Packages\CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc\LocalState\rootfs\home\emiliano\linux-4.9.66

rem ===== Additional QEMU Configs =====
set QEMU_PARAMETERS=%QEMU_PARAMETERS% -monitor telnet:127.0.0.1:5020,server,nowait
set QEMU_PARAMETERS=%QEMU_PARAMETERS% -usb -device usb-kbd -device usb-mouse

rem set QEMU_PARAMETERS=%QEMU_PARAMETERS% -device usb-storage,drive=usbdrive,removable=on,id=usbdevice -drive file=%USERPROFILE%\Desktop\USB.img,id=usbdrive,if=none,format=raw

rem ========================================

cd %~dp0

set KERNEL_PATH=boot

2>NUL call :CASE_%MACHINE%
IF ERRORLEVEL 1 CALL :DEFAULT_CASE

IF DEFINED DTB_FILE (
	set DTB=-dtb %KERNEL_PATH%\%KVER%\%DTB_FILE%
)

IF %CPUS% GEQ 2 (
	set SMP=-smp %CPUS%
)

IF "%CTLDEVICE%"=="virtio-blk-device" (
	set STORAGESTRING=-device %CTLDEVICE%,drive=disk0 -drive file=%IMAGE%,if=%DISKDEVICE%,format=%IMAGEFMT%,id=disk0
) ELSE (
	set STORAGESTRING=-drive file=%IMAGE%,if=%DISKDEVICE%,format=%IMAGEFMT%
)

IF DEFINED NETDEVICE (
	set NETWORKSTRING=-device %NETDEVICE%,netdev=eth0 -netdev user,id=eth0,hostfwd=tcp::5022-:22,hostfwd=tcp::5080-:80
)

IF DEFINED SERIALDEVICE (
	set SERIALSTRING=-device %SERIALDEVICE%,chardev=ttyS0 -chardev socket,id=ttyS0,port=5021,host=0.0.0.0,nodelay,server,nowait,telnet
	) ELSE (
	set SERIALSTRING=-serial stdio
)

IF DEFINED NOGRAPHIC (
	set APPEND=%APPEND% console=ttyAMA0,115200
) ELSE (
	set APPEND=%APPEND% console=tty1
)
set APPEND="%APPEND%"

set BASECMD="%PROGRAMFILES%"\qemu\qemu-system-aarch64.exe -machine %MACHINE%
set RUNLINE=%BASECMD% -kernel %KERNEL_PATH%\%KVER%\%KERNEL_IMAGE% %DTB% %SMP% -m %MEM% -append %APPEND% %NOGRAPHIC% --no-reboot %QEMU_PARAMETERS% %STORAGESTRING% %NETWORKSTRING% %SERIALSTRING%
set HELPLINE=%BASECMD% -device help

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
if "%DEVICEHELP%"=="1" (
	echo %HELPLINE%
	%HELPLINE%
) ELSE (
	echo %RUNLINE%
	%RUNLINE%
)
echo.

pause
exit /B

:CASE_raspi2
set KERNEL_IMAGE=kernel7.img
set DTB_FILE=bcm2709-rpi-2-b.dtb
set CPUS=4
set MEM=1024
set DISKDEVICE=sd
set NETDEVICE=usb-net
set SERIALDEVICE=usb-serial
set QEMU_PARAMETERS=%QEMU_PARAMETERS% -cpu cortex-a7
set APPEND=%APPEND% root=/dev/mmcblk0p2
rem set QEMU_PARAMETERS=%QEMU_PARAMETERS%
rem set NOGRAPHIC=-nographic
goto END_CASE

:CASE_raspi3
set KERNEL_IMAGE=kernel8.img
set DTB_FILE=bcm2710-rpi-3-b.dtb
set CPUS=4
set MEM=1024
set DISKDEVICE=sd
set NETDEVICE=usb-net
set SERIALDEVICE=usb-serial
set QEMU_PARAMETERS=%QEMU_PARAMETERS% -cpu cortex-a53
set APPEND=%APPEND% root=/dev/mmcblk0p2
rem set NOGRAPHIC=-nographic
goto END_CASE

:CASE_virt
set KERNEL_IMAGE=linux-%MACHINE%
set CPUS=2
set MEM=1024
set CTLDEVICE=virtio-blk-device
set DISKDEVICE=sd
set NETDEVICE=virtio-net-device
rem set SERIALDEVICE=usb-serial
set QEMU_PARAMETERS=-device usb-ehci %QEMU_PARAMETERS% -cpu cortex-a7 -device virtio-gpu-pci -vga std -device virtio-rng-pci -device intel-hda -audiodev dsound,id=default
set APPEND=%APPEND% root=/dev/vda2
set NOGRAPHIC=-nographic
goto END_CASE

:CASE_virt64
set KERNEL_IMAGE=linux-%MACHINE%
set CPUS=4
set MEM=2048
set CTLDEVICE=virtio-blk-device
set DISKDEVICE=sd
set NETDEVICE=virtio-net-device
set QEMU_PARAMETERS=-device usb-ehci %QEMU_PARAMETERS% -cpu cortex-a53 -device virtio-gpu-pci -vga std -device virtio-rng-pci -device intel-hda -audiodev dsound,id=default
set APPEND=%APPEND% root=/dev/vda2
rem set NOGRAPHIC=-nographic
set MACHINE=virt
goto END_CASE

:DEFAULT_CASE
ECHO "%MACHINE%" not supported
GOTO :EOF

:END_CASE
VER > NUL
GOTO :EOF
