#!/bin/bash

bridge="$1"

# required packages
packages=(
	"libnl-3-200_3.4.0-1_armhf.deb"
	"libnl-genl-3-200_3.4.0-1_armhf.deb"
	"batctl_2019.0-1_armhf.deb"
)

# add bridge-utils if a bridge device
if $bridge ; then
	packages+=("bridge-utils_1.5-13+deb9u1_armhf.deb")
fi

if ! command -v batctl; then
	for i in "${packages[@]}"; do dpkg -i "/deps/$i"; done
fi

# Activate batman-adv
modprobe batman-adv

# Disable and configure wlan0
ifconfig wlan0 down
# stop wpa supplicant from locking if
pkill -9 wpa_supplicant
sleep 2s

# change if mode
iwconfig wlan0 \
	mode ad-hoc \
	essid meshpinet \
	ap 02:12:34:56:78:9A \
	channel 1
sleep 2s

# add wlan to bat
batctl if add wlan0
sleep 2s

# bring if back up
ifconfig wlan0 up
ifconfig bat0 up
sleep 4s

if $bridge; then
	#setup the bridge
	brctl addbr bri0

	brctl addif bri0 bat0
	brctl addif bri0 eth0

	dhclient bri0

else
	# get the ip for the if
	dhclient bat0
fi
