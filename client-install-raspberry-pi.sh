#!/bin/bash

# Stream-Pi Client Installer Script for Raspberry Pi 
# This Script heavily makes use of some code from the official raspi-config script (https://github.com/RPi-Distro/raspi-config)

VERSION=1.1.0
CONFIG=/boot/config.txt
NINENINERULES=/etc/udev/rules.d/99-com.rules
INSTALL_DIRECTORY=$HOME # current user's home dir as default
FOLDER_NAME=stream-pi-client/
DESKTOP_SHORTCUT="${HOME}/Desktop/Stream-Pi Client.desktop"
CREATE_SHORTCUT=true
SLEEP_DURATION=10
GPU_MEM=128
DOWNLOAD_LINK=https://github.com/stream-pi/client/releases/download/1.0.0-EA%2B3/stream-pi-client-linux-arm32-1.0.0-EA+3-executable.zip
DEBUG=0
CHANGE_BACKLIGHT_PERMISSIONS=true

# Necessary Methods
is_pi() {
  ARCH=$(dpkg --print-architecture)
  if [ "$ARCH" = "armhf" ] || [ "$ARCH" = "arm64" ] ; then
    return 0
  else
    return 1
  fi
}

usage() {
  cat << EOF
Usage: client-install-raspberry-pi.sh [-h | --help] [-v | --verbose]    
                                      [-d | --download-link] [-g | --gpu-mem]    
                                      [-i | --install-dir] [-c | --client-dir]
                                      [-s | --skip-shortcut] [-b | --backlight-no]

If no arguments are provided, installation will continue using the default
values.
    -h --help           Print this message
    -v --verbose        Print debug information
    -d --download-link  Set custom download link for Stream-Pi client.
                        Defaults to the latest stable release.
    -g --gpu-mem        Set custom GPU memory split, defaults to 128.
    -i --install-dir    Set custom root installation directory.
                        Defaults to user's home directory.
    -c --client-dir     Set custom directory for the client application.
                        This will be a sub-directory under 'install-dir',
                        defaults to 'stream-pi-client/'
    -s --skip-shortcut  Does not create shortcut in Desktop
    -b --backlight-no   Does not modify Official Screen backlight persmissions.
EOF
}

parse_params() {
  while :; do
    case "${1-}" in
    -h | --help) usage && exit 0 ;;
    -v | --verbose) DEBUG=1 ;;
    -d | --download-link)
      DOWNLOAD_LINK="${2-}"
      shift
      ;;
    -g | --gpu-mem)
      GPU_MEM="${2-}"
      shift
      ;;
    -i | --install-dir)
      INSTALL_DIRECTORY="${2-}"
      shift
      ;;
    -c | --client-dir)
      FOLDER_NAME="${2-}"
      shift
      ;;
    -s | --skip-shortcut)
      CREATE_SHORTCUT=false
      shift
      ;;
    -b | --backlight-no)
      CHANGE_BACKLIGHT_PERMISSIONS=false
      shift
      ;;
    *) break ;;
    esac
    shift
  done
}

print_params() {
  cat << EOF
Installation params:
---
DOWNLOAD_LINK=$DOWNLOAD_LINK
GPU_MEM=$GPU_MEM
INSTALL_DIRECTORY=$INSTALL_DIRECTORY
FOLDER_NAME=$FOLDER_NAME
---
EOF
}

# Check whether this is even a pi or not
if ! is_pi; then
  echo This is not a Pi. This script is only for Raspberry Pi Devices.
  exit 1
fi

echo Stream-Pi Client Installer Script For Raspberry Pi
echo Version "$VERSION"

parse_params "$@"

if [ "$DEBUG" -eq 1 ]; then
  print_params
fi

# Install required dependencies ...

echo Installing required dependencies ...

if ! sudo apt -y update ; then
   echo Unable to run apt update. Check internet connection / permissions. Quitting ...
   exit 1
fi

if ! sudo apt -y install unzip axel libegl-mesa0 libegl1 libgbm1 libgles2 libpango-1.0.0 libpangoft2-1.0.0 libgl1-mesa-dri gldriver-test ; then
   echo Unable to install required dependencies. Quitting ...
   exit 1
fi



# Finally Download and extract

echo Downloading Client ...

cd "$HOME"
if ! axel -k -a -n 4 --output=spi.zip $DOWNLOAD_LINK ; then
   echo Unable to Download. Quitting ...
   exit 1
fi


if [ -d "${HOME}/Stream-Pi/" ] ||  [ -d "$INSTALL_DIRECTORY/$FOLDER_NAME" ]; then
echo Previous Clean up ...
rm -rf "${HOME}/Stream-Pi/"
rm -rf "$INSTALL_DIRECTORY/$FOLDER_NAME"
fi





echo Extracting ...


unzip spi.zip -d "$FOLDER_NAME"

echo Clean up ...
rm -rf spi.zip

echo Setting permissions ...
cd "$FOLDER_NAME"
chmod +x run_console
chmod +x run_desktop
chmod +x jre/bin/java


# Add support for touch 

echo Adding touch support ...

# Check if already exists 


if grep -q -E "chown -R root:input /sys/class/input/\*/ && chmod -R 770 /sys/class/input/\*/;" "$NINENINERULES" ; then
echo Touch support already exists ...
else
sudo tee -a "$NINENINERULES" > /dev/null <<EOT
SUBSYSTEM=="input*", PROGRAM="/bin/sh -c '\
chown -R root:input /sys/class/input/*/ && chmod -R 770 /sys/class/input/*/;\
'"
EOT
fi


# Allow non-root change of backlight power

if [ "$CHANGE_BACKLIGHT_PERMISSIONS" == true ]; then
echo Adding backlight power change permission ...
echo 'SUBSYSTEM=="backlight",RUN+="/bin/chmod 666 /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power"' | sudo tee -a /etc/udev/rules.d/backlight-permissions.rules
fi

# Turn on FAKE KMS Driver

echo Turning ON FAKE KMS Driver ...

sudo sed "$CONFIG" -i -e "s/^dtoverlay=vc4-kms-v3d/#dtoverlay=vc4-kms-v3d/g"
sudo sed "$CONFIG" -i -e "s/^dtoverlay=vc4-fkms-v3d/ /g"
if ! sudo sed -n "/\[pi4\]/,/\[/ !p" "$CONFIG" | grep -q "^dtoverlay=vc4-fkms-v3d" ; then
	sudo sh -c "printf 'dtoverlay=vc4-fkms-v3d\n' >> $CONFIG"
fi



# Add GPU MEM

echo Setting gpu_mem to "$GPU_MEM" MB ...

sudo sed "$CONFIG" -i -e "s/^gpu_mem=/#gpu_mem=/g"
sudo sed "$CONFIG" -i -e "s/^#gpu_mem=$GPU_MEM/gpu_mem=$GPU_MEM/g"
if ! sudo sed -n "/\[pi4\]/,/\[/ !p" "$CONFIG" | grep -q "^gpu_mem=$GPU_MEM" ; then
	sudo sh -c "printf 'gpu_mem=$GPU_MEM\n' >> $CONFIG"
fi


# Create desktop shortcut

if [ ! -d "${HOME}/Desktop" ] &&  [ "$CREATE_SHORTCUT" == true ]; then
echo Skip create Desktop shortcut since "${HOME}/Desktop" does not exist.
CREATE_SHORTCUT=false
fi


if [ "$CREATE_SHORTCUT" == true ]; then

sudo rm -rf "${DESKTOP_SHORTCUT}"

echo Creating desktop shortcut : "$DESKTOP_SHORTCUT"

tee -a "$DESKTOP_SHORTCUT" > /dev/null <<EOT
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=Stream-Pi Client (Desktop Mode)
Comment=Cross Platform Macropad Software
Icon=$INSTALL_DIRECTORY/$FOLDER_NAME/app-icon.png
Exec=$INSTALL_DIRECTORY/$FOLDER_NAME/run_desktop
Terminal=false
EOT

chmod +x "${DESKTOP_SHORTCUT}"

fi


# Finish Message

cat << EOF
Stream-Pi Client is now successfully installed. However your Pi needs to be restarted
After Restart, You may cd to "$INSTALL_DIRECTORY/$FOLDER_NAME"
and run './run_console' to run in Console mode using KMS Driver (Recommended)
or run './run_desktop' to run in Desktop Mode without hardware acceleration.

WARNING: You cannot run Stream-Pi Client as desktop mode while you are in console mode, and vice versa.
EOF

if [ "$CREATE_SHORTCUT" == true ]; then
echo A desktop shortcut has also been created in $HOME/Desktop for ease of use.
fi

echo Restarting in $SLEEP_DURATION seconds ...

sleep $SLEEP_DURATION

sudo reboot
