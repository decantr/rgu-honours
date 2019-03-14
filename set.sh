#!/bin/bash

## get the ip address of the device from the hostname
#addr=$(hostname | sed 's/[^0-9]*//g')

packages=(
	"libnl-3-200_3.4.0-1_armhf.deb"
	"libnl-genl-3-200_3.4.0-1_armhf.deb"
	"batctl_2019.0-1_armhf.deb"
	"bridge-utils_1.6-2_armhf.deb"
)

if [ -f /log.log ] ; then rm /log.log; fi

touch /log.log

if command -v batctl; then
	echo "batctl found" | tee -a /log.log
else
	echo "batctl not found, installing" | tee -a /log.log
	for i in "${packages[@]}"; do
		echo "installing $i" | tee -a /log.log
		dpkg -i "/deps/$i" | tee /dpkg.log
	done
fi

# iwconfig wlan0 ap DE:FC:20:38:01:C5

echo "activating batman" | tee -a /log.log
# Activate batman-adv
modprobe batman-adv

echo "bringing wlan0 down" | tee -a /log.log
# Disable and configure wlan0
ip link set wlan0 down
# stop wpa supplicant from locking if
echo "killing wpa_supplicant" | tee -a /log.log
systemctl stop wpa_supplicant
pkill -9 wpa_supplicant

sleep 2s

# change if mode
echo "changing wlan0 mode" | tee -a /log.log
iwconfig wlan0 \
	mode ad-hoc \
	essid mymesh \
	ap any \
	channel 8

sleep 1s

# add wlan to bat
echo "adding bat0 to wlan0" | tee -a /log.log
batctl if add wlan0
sleep 1s

# bring if back up
echo "bring if back up" | tee -a /log.log
ip link set wlan0 up
ip link set bat0 up
sleep 4s

# create bridge
if hostname | grep "pihost"; then
	echo "setting up bridge" | tee -a /log.log
#	ip link add name brid type bridge
#	ip link set brid up

#	ip link set eth0 master brid
#	ip link set bat0 master brid
	# get ip for the bridge

	brctl addbr br0
	brctl addif br0 eth0

	dhclient brid
else
	# get the ip for the if
	echo "getting ip address" | tee -a /log.log
	dhclient bat0
fi

# Use different IPv4 addresses for each device
# This is the only change necessary to the script for
# different devices. Make sure to indicate the number
# of bits used for the mask.
# ifconfig bat0 172.27.0.1/16

sleep 5s

# iwconfig wlan0 ap DE:FC:20:38:01:C5

echo "print ip address info" | tee -a /log.log
ip a | tee /ip.out
echo "print iw info" | tee -a /log.log
iwconfig | tee -a /ip.out
echo "print batman info" | tee -a /log.log
batctl o | tee -a /ip.out
