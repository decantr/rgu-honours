#!/bin/bash

# required packages
packages=(
	"libnl-3-dev_3.2.27-2_armhf.deb"
	"libnl-genl-3-dev_3.2.27-2_armhf.deb"
)

if ! command -v batctl; then
	for i in "${packages[@]}"; do dpkg -i "/deps/$i"; done
	tar xf "/deps/batctl-2017.3.tar.gz"
	cd "batctl-2017.3"
	make install
fi


# Activate batman-adv
modprobe batman-adv

# Disable and configure wlan0
ip link set wlan0 down
# stop wpa supplicant from locking if
systemctl stop wpa_supplicant
pkill -9 wpa_supplicant
sleep 2s

# change if mode
iwconfig wlan0 \
	mode ad-hoc \
	essid meshpinet \
	ap any \
	channel 1
sleep 2s

# add wlan to bat
batctl if add wlan0
sleep 2s

# bring if back up
ip link set dev wlan0 up
ip link set dev bat0 up
sleep 4s

ip addr add 172.16.0.$IP/24 dev bat0
