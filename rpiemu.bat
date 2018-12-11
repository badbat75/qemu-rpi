@echo off

rem ===== Set the MACHINE variable =====
rem Possible values:
rem	       raspi2
rem	       raspi3
rem	       virt
rem        versatilepb
rem        vexpress-a9
set MACHINE=raspi2

rem ===== Set the default IMAGE =====
set DEFIMAGE=2018-10-09-raspbian-stretch-lite.img

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
set KERNEL_SOURCE_PATH=%USERPROFILE%\AppData\Local\Packages\CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc\LocalState\rootfs\home\emiliano\linux-4.9.66

rem ===== Additional QEMU Configs =====
set QEMU_PARAMETERS=%QEMU_PARAMETERS% -monitor telnet:127.0.0.1:5021,server,nowait

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
	set STORAGESTRING=-drive file=%IMAGE%,if=%DISKDEVICE%,format=%IMAGEFMT%
)

IF DEFINED NETDEVICE (
	set NETWORKSTRING=-device %NETDEVICE%,netdev=eth0 -netdev user,id=eth0,hostfwd=tcp::5022-:22,hostfwd=tcp::5080-:80
)

IF DEFINED NOGRAPHIC (
	set APPEND=%APPEND% console=ttyAMA0,115200
) ELSE (
	set APPEND=%APPEND% console=tty1
)
set APPEND="%APPEND%"

set BASECMD="%PROGRAMFILES%"\qemu\qemu-system-aarch64.exe -machine %MACHINE%
set RUNLINE=%BASECMD% -kernel %KERNEL_PATH%%KERNEL_IMAGE% %DTB% %SMP% -m %MEM% -serial stdio -append %APPEND% %STORAGESTRING% %NETWORKSTRING% %NOGRAPHIC% --no-reboot %QEMU_PARAMETERS%
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
set APPEND=%APPEND% root=/dev/mmcblk0p2
rem set NETDEVICE=usb-net
set QEMU_PARAMETERS=%QEMU_PARAMETERS% -usb -device usb-kbd -device usb-mouse -device usb-net,netdev=usb0 -netdev user,id=usb0,hostfwd=tcp::5022-:22,hostfwd=tcp::5080-:80
goto END_CASE

:CASE_raspi3
set KERNEL_IMAGE=vmlinuz-4.9.0-8-arm64
set DTB_FILE=bcm2710-rpi-3-b.dtb
set CPUS=4
set MEM=1024
set DISKDEVICE=sd
set APPEND=%APPEND% root=/dev/mmcblk0p2
rem set NETDEVICE=usb-net
set QEMU_PARAMETERS=%QEMU_PARAMETERS% -usb -device usb-kbd -device usb-mouse -device usb-net,netdev=usb0 -netdev user,id=usb0,hostfwd=tcp::5022-:22,hostfwd=tcp::5080-:80
goto END_CASE

:CASE_versatilepb
set KERNEL_IMAGE=linux-4.14.37-versatile
set DTB_FILE=versatile-pb.dtb
set CPUS=1
set MEM=256
rem set CTLDEVICE=<not supported>
rem set DISKDEVICE=<not supported>
set QEMU_PARAMETERS=%QEMU_PARAMETERS% -usb -device usb-ehci
set APPEND=%APPEND% root=PARTUUID=c7cb7e34-02
goto END_CASE

:CASE_vexpress-a9
set KERNEL_IMAGE=linux-4.14.37-vexpress
set DTB_FILE=vexpress-v2p-ca9.dtb
set CPUS=2
set MEM=1024
set CTLDEVICE=virtio-blk-device
set DISKDEVICE=none
set NETDEVICE=virtio-net-device
set APPEND=%APPEND% root=/dev/vda2
goto END_CASE

:CASE_virt
set KERNEL_IMAGE=linux-4.14.37-vexpress
set CPUS=2
set MEM=1024
set CTLDEVICE=virtio-blk-device
set DISKDEVICE=none
set NETDEVICE=virtio-net-device
set QEMU_PARAMETERS=%QEMU_PARAMETERS% -usb -device usb-ehci
set APPEND=%APPEND% root=/dev/vda2
set NOGRAPHIC=-nographic
goto END_CASE

:DEFAULT_CASE
ECHO "%MACHINE%" not supported
GOTO :EOF

:END_CASE
VER > NUL
GOTO :EOF
