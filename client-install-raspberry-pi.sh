#!/bin/bash

# Stream-Pi Client Installer Script for Raspberry Pi 
# This Script heavily makes use of some code from the official raspi-config script (https://github.com/RPi-Distro/raspi-config)

VERSION=1.0.0
CONFIG=/boot/config.txt
NINENINERULES=/etc/udev/rules.d/99-com.rules
INSTALL_DIRECTORY=$HOME # current user's home dir as default
FOLDER_NAME=stream-pi-client/
GPU_MEM=128
DOWNLOAD_LINK=https://github.com/stream-pi/client/releases/download/1.0.0/client-linux-arm7-1.0.0-EA+2.zip




# Necessary Methods

set_config_var() {
local key=assert(arg[1])
local value=assert(arg[2])
local fn=assert(arg[3])
local file=assert(io.open(fn))
local made_change=false
for line in file:lines() do
  if line:match("^#?%s*"..key.."=.*$") then
    line=key.."="..value
    made_change=true
  end
  print(line)
end

if not made_change then
  print(key.."="..value)
end
EOF
}

is_pi() {
  ARCH=$(dpkg --print-architecture)
  if [ "$ARCH" = "armhf" ] || [ "$ARCH" = "arm64" ] ; then
    return 0
  else
    return 1
  fi
}


# Check whether this is even a pi or not

if ! is_pi ; then
   echo This is not a Pi. This script is only for Raspberry Pi Devices.
   exit 1
fi

# set custom download link if provided
if [[ ! -z "$1" ]]; then
   DOWNLOAD_LINK="$1"
fi

# set custom GPU memory split if provided
if [[ ! -z "$2" ]]; then
   GPU_MEM="$2"
fi

# set custom installation directory if provided
if [[ ! -z "$3" ]]; then
   INSTALL_DIRECTORY="$3"
fi

# set custom folder if provided
if [[ ! -z "$4" ]]; then
   FOLDER_NAME="$4"
fi




echo Stream-Pi Client Installer Script For Raspberry Pi
echo Version "$VERSION"


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
if ! axel -a -n 4 --output=spi.zip https://github.com/stream-pi/client/releases/download/1.0.0/client-linux-arm7-1.0.0-EA+2.zip ; then
   echo Unable to Download. Quitting ...
   exit 1
fi

echo Previous Clean up ...
rm -rf ~/Stream-Pi/
rm -rf "$FOLDER_NAME"



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


# Turn on FAKE KMS Driver

echo Turning ON FAKE KMS Driver ...

sudo sed "$CONFIG" -i -e "s/^dtoverlay=vc4-kms-v3d/#dtoverlay=vc4-kms-v3d/g"
sudo sed "$CONFIG" -i -e "s/^#dtoverlay=vc4-fkms-v3d/dtoverlay=vc4-fkms-v3d/g"
if ! sudo sed -n "/\[pi4\]/,/\[/ !p" "$CONFIG" | grep -q "^dtoverlay=vc4-fkms-v3d" ; then
   printf "[all]\ndtoverlay=vc4-fkms-v3d\n" | sudo tee "$CONFIG"
fi


# Add GPU MEM

echo Setting gpu_mem to "$GPU_MEM" MB ...

set_config_var gpu_mem "$GPU_MEM" $CONFIG


cat << EOF
Stream-Pi Client is installed. However your Pi needs to be restarted
After Restart, You may cd to "$INSTALL_DIRECTORY/$FOLDER_NAME"
and run './run_console' or './run_desktop'
Restarting in 5 seconds ...
EOF

sleep 5

sudo reboot

