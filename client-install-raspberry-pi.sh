#!/bin/bash

# Stream-Pi - Free & Open-Source Modular Cross-Platform Programmable Macro Pad
# Copyright (C) 2019-2021  Debayan Sutradhar (rnayabed),  Samuel Quiñones (SamuelQuinones)
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# Original Authors : Debayan Sutradhar (@rnayabed), Jordan Duabe (@j4ckofalltrades)

# Installer Script for Raspberry Pi 

VERSION=2.7
DOWNLOAD_LINK=https://github.com/stream-pi/client/releases/download/1.0.0-EA%2B3/stream-pi-client-linux-arm32-1.0.0-EA+3-executable.zip
CONFIG=/boot/config.txt
NINE_NINE_RULES_FILE=/etc/udev/rules.d/99-com.rules
BACKLIGHT_PERMISSIONS_RULES_FILE=/etc/udev/rules.d/backlight-permissions.rules
INSTALL_DIRECTORY=$HOME # current user's home dir as default
FOLDER_NAME=stream-pi-client/
DESKTOP_SHORTCUT="${HOME}/Desktop/Stream-Pi Client.desktop"
CREATE_SHORTCUT=true
SLEEP_DURATION=10
GPU_MEM=128
DEBUG=0
CHANGE_BACKLIGHT_PERMISSIONS=true
AXEL_THREADS=4
DOWNLOAD=true
ZIP_FILE="spi.zip"
PRESERVE_DATA=false
ADD_TOUCH_SUPPORT=true
USE_WGET=false
SKIP_KMS_PROMPT=0
# SKIP_KMS_PROMPT details
# 0 = DONT SKIP
# 1 = SKIP AND ENABLE 
# 2 = SKIP AND DONT ENABLE



# Necessary Methods
is_pi() {
  ARCH=$(dpkg --print-architecture)
  if [ "$ARCH" = "armhf" ] || [ "$ARCH" = "arm64" ] ; then
    return true
  else
    return false
  fi
}

is_fkms() {
  if grep -s -q okay /proc/device-tree/soc/v3d@7ec00000/status \
                     /proc/device-tree/soc/firmwarekms@7e600000/status \
                     /proc/device-tree/v3dbus/v3d@7ec04000/status; then
    return true
  else
    return false
  fi
}

usage() {
  cat << EOF
Usage:  [-h | --help] [-v | --verbose]    
        [-d | --download-link] [-g | --gpu-mem]    
        [-i | --install-dir] [-c | --client-dir]
        [-s | --skip-shortcut] [-b | --backlight-no]
        [-ky | --enable-kms] [-kn | --dont-enable-kms] 
        [-z | --zip] [-p | --preserve-old-data]
        [-t | --dont-add-touch] [-at | --axel-threads]
        [-uw | --use-wget]

If no arguments are provided, installation will continue using the default
values.
    -h  --help                Print this message.
    -v  --verbose             Print debug information.
    -d  --download-link       Set custom download link for Stream-Pi client.
                              Defaults to the latest stable release.
    -g  --gpu-mem             Set custom GPU memory split, defaults to 128.
    -i  --install-dir         Set custom root installation directory.
                              Defaults to user's home directory.
    -c  --client-dir          Set custom directory for the client application.
                              This will be a sub-directory under 'install-dir',
                              defaults to 'stream-pi-client/'.
    -s  --skip-shortcut       Does not create shortcut in Desktop.
    -b  --backlight-no        Does not modify Official Screen backlight persmissions.
    -ky --enable-kms          Skips user prompt and turns on KMS driver.
    -kn --dont-enable-kms     Skips user prompt and does not turn on KMS driver.
    -z  --zip-file            Use custom zip instead of downloading.
    -p  --preserve-old-data   Skips user data and preserve previous Stream-Pi data (if found).
                              Not recommended for upgrading to different versions.
    -t  --dont-add-touch      Does not add touch support. 
                              Not recommended if Client is to be used in Console mode.
    -at --axel-threads        Specify number of axel threads while downloading. Default is 4.
    -uw --use-wget            Use wget instead of axel to download.
EOF
}

parse_params() {
  while :; do
    case "${1-}" in
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
      ;;
    -b | --backlight-no)
      CHANGE_BACKLIGHT_PERMISSIONS=false
      ;;
    -ky | --enable-kms)
      SKIP_KMS_PROMPT=1
      ;;
    -kn | --dont-enable-kms)
      SKIP_KMS_PROMPT=2
      ;;
    -z | --zip-file)
      DOWNLOAD=false
      ZIP_FILE="${2-}"
      shift
      ;;
    -p | --preserve-old-data)
      PRESERVE_DATA=true
      ;;
    -t | --dont-add-touch)
      ADD_TOUCH_SUPPORT=false
      ;;
    -at | --axel-threads)
      AXEL_THREADS=${2-}
      shift
      ;;
    -uw | --use-wget)
      USE_WGET=true
      ;;
    *) 
      if [ ! -z "${1-}" -a "${1-}" != " " ]; then
        usage 
        exit 0
      else
        break
      fi
      ;;
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
CREATE_SHORTCUT=$CREATE_SHORTCUT
CHANGE_BACKLIGHT_PERMISSIONS=$CHANGE_BACKLIGHT_PERMISSIONS
SKIP_KMS_PROMPT=$SKIP_KMS_PROMPT
DOWNLOAD=$DOWNLOAD
ZIP_FILE=$ZIP_FILE
ADD_TOUCH_SUPPORT=$ADD_TOUCH_SUPPORT
AXEL_THREADS=$AXEL_THREADS
USE_WGET=$USE_WGET
---
EOF
}

# Check whether this is a pi or not
if [ ! is_pi ]; then
  echo This script is only for Raspberry Pi Devices.
  exit 1
fi

parse_params "$@"

if [ "$DEBUG" -eq 1 ]; then
  print_params
fi

# Print intro


cat << EOF
                                                
         ,***///****.      ,****///***,         
        .*//*,,*//////,  *//////*,**//*.        
         ,//////**,,*/*  */*,,**/////*.         
           ,////////.      ,////////,           
             ..,,..    (/    .,,,..             
                    .(@@@@/.                    
            *&@@@&(*,.    .,*(&@@@&/            
           /@@@/                /@@@/           
          *&@(     .,. .,.        /@&*          
        ,&@@/     #@&#&@%%@&(,     /@@&,        
        (@@&.     #@* &@.   ,#@&(  .&@@(        
         #@@.     #@* &@.  ,#&&(.  .&@#         
          (@#     /@@&%@@@&/.      #@(          
           %@%.                  .%@%           
            *&@&*              *&@&*            
               ,#&&%(/****/(%&&#,               
                   .(@@@@@&(.                   
                                                                                                             

   Stream-Pi Client Installer For Raspberry Pi
                     v$VERSION
EOF


# Update ...

echo $'\nUpdate ...'

sudo apt-get --allow-releaseinfo-change update
if [ $? -ne 0 ]; then
   echo Unable to run apt update. Check internet connection / permissions. Quitting ...
   exit 1
fi


# Installing required dependencies ...

echo $'\nInstalling required dependencies ...'

if ! sudo apt-get install wget unzip axel libegl-mesa0 libegl1 libgbm1 libgles2 libpango-1.0.0 libpangoft2-1.0.0 libgl1-mesa-dri gldriver-test ; then
   echo Unable to install required dependencies. Quitting ...
   exit 1
fi


# Delete old client

if [ -d "$INSTALL_DIRECTORY/$FOLDER_NAME" ]; then
echo $'\nDeleting existing Stream-Pi Client ...'
rm -rf "$INSTALL_DIRECTORY/$FOLDER_NAME"
fi

# Delete old data 

if [ -d "${HOME}/Stream-Pi/" ]; then
  if [ "$PRESERVE_DATA" == false ]; then
    echo $'\nDelete old data ...'
    rm -rf "${HOME}/Stream-Pi/"  
  fi
fi



# Finally Download and extract

if [ "$DOWNLOAD" == true ]; then
echo $'\nDownloading Client ...'

cd "$HOME"

if [ "$USE_WGET" == true ]; then

if ! wget $DOWNLOAD_LINK -O "$ZIP_FILE" ; then
   echo Unable to Download. Quitting ...
   exit 1
fi

else

if ! axel -k -a -n $AXEL_THREADS --output="$ZIP_FILE" $DOWNLOAD_LINK ; then
   echo Unable to Download. Quitting ...
   exit 1
fi

fi


fi



echo $'\nExtracting ...'
unzip "$ZIP_FILE" -d "$FOLDER_NAME"



if [ "$DOWNLOAD" == true ]; then
echo $'\nClean up ...'
rm -rf "$ZIP_FILE"
fi


echo $'\nSetting permissions ...'
cd "$FOLDER_NAME"
chmod +x run_console
chmod +x run_desktop

if [ -f jre/bin/java ]; then
    chmod +x jre/bin/java
fi




# Add support for touch 

grep -q -E "chown -R root:input /sys/class/input/\*/ && chmod -R 770 /sys/class/input/\*/;" "$NINE_NINE_RULES_FILE"
if [ $? -ne 0 ] && [ "$ADD_TOUCH_SUPPORT" == true ]; then
echo $'\nAdding touch support ...'
sudo tee -a "$NINE_NINE_RULES_FILE" > /dev/null <<EOT
SUBSYSTEM=="input*", PROGRAM="/bin/sh -c '\
chown -R root:input /sys/class/input/*/ && chmod -R 770 /sys/class/input/*/;\
'"
EOT
fi


# Allow non-root change of backlight power

if [ "$CHANGE_BACKLIGHT_PERMISSIONS" == true ]; then
echo $'\nAdding backlight power change permission ...'
sudo tee -a "$BACKLIGHT_PERMISSIONS_RULES_FILE" > /dev/null <<EOT
SUBSYSTEM=="backlight",RUN+="/bin/chmod 666 /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power"
EOT
fi

# Turn on FAKE KMS Driver

enable_kms() {
  echo $'\nTurning ON FAKE KMS Driver ...'

  sudo sed "$CONFIG" -i -e "s/^dtoverlay=vc4-kms-v3d/#dtoverlay=vc4-kms-v3d/g"
  sudo sed "$CONFIG" -i -e "s/^dtoverlay=vc4-fkms-v3d/ /g"
  if ! sudo sed -n "/\[pi4\]/,/\[/ !p" "$CONFIG" | grep -q "^dtoverlay=vc4-fkms-v3d" ; then
	  sudo sh -c "printf 'dtoverlay=vc4-fkms-v3d\n' >> $CONFIG"
  fi

}

if [ is_fkms ] && [ ! -d "/dev/dri" ]; then

if [ "$SKIP_KMS_PROMPT" == 0 ]; then
cat << EOF

===================================
ATTENTION! PLEASE READ CAREFULLY!

Stream-Pi Client can run either in Console Mode or Desktop Mode.
It is recommended to use console mode as Stream-Pi Client can then leverage Hardware acceleration and offer a smooth experience.

Stream-Pi Client CANNOT run in console mode with the KMS Driver turned OFF.

To ensure maximum compatibility, Stream-Pi Client can also run in Desktop Mode in case KMS is not available/disabled.

However, certain screens like the HyperPixel for Raspberry Pi conflicts with the KMS driver.
Stream-Pi Client can still run on these screens using desktop mode.

Fortunately, most screens like the Official 7" Raspberry Pi Display, Waveshare screens (including clones) work well with KMS Driver.



You can later disable or enable the KMS driver using the "raspi-config" tool, or by modifying /boot/config.txt

Do you want to turn on the KMS Driver ? [Y/N]
EOF
read -n 1 -r </dev/tty
echo  
if [[ $REPLY =~ ^[Yy]$ ]]; then
  enable_kms
fi


elif [ "$SKIP_KMS_PROMPT" == 1 ]; then
  enable_kms
fi

fi





# Add GPU MEM

echo
echo Setting gpu_mem to "$GPU_MEM" MB ...

sudo sed "$CONFIG" -i -e "s/^gpu_mem=/#gpu_mem=/g"
sudo sed "$CONFIG" -i -e "s/^#gpu_mem=$GPU_MEM/gpu_mem=$GPU_MEM/g"
if ! sudo sed -n "/\[pi4\]/,/\[/ !p" "$CONFIG" | grep -q "^gpu_mem=$GPU_MEM" ; then
	sudo sh -c "printf 'gpu_mem=$GPU_MEM\n' >> $CONFIG"
fi


# Create desktop shortcut

if [ ! -d "${HOME}/Desktop" ] &&  [ "$CREATE_SHORTCUT" == true ]; then
CREATE_SHORTCUT=false
fi


if [ "${CREATE_SHORTCUT}" == true ]; then

sudo rm -rf "${DESKTOP_SHORTCUT}"

echo Creating desktop shortcut : $DESKTOP_SHORTCUT

tee -a "${DESKTOP_SHORTCUT}" > /dev/null <<EOT
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
===================================

Stream-Pi Client is now successfully installed. However your Pi needs to be restarted.

After Restart, You may cd to "$INSTALL_DIRECTORY/$FOLDER_NAME"
and run './run_console' to run in Console mode using KMS Driver (Recommended)
or run './run_desktop' to run in Desktop Mode without hardware acceleration.

WARNING: You cannot run Stream-Pi Client as desktop mode while you are in console mode, and vice versa.
EOF

if [ "$CREATE_SHORTCUT" == true ]; then
echo A desktop shortcut has also been created in $HOME/Desktop for ease of use.
fi

echo $'\nRestart now? [Y/N]\n'
read -n 1 -r </dev/tty
echo  
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo reboot
fi

