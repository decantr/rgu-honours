#!/bin/bash

bridge="$1"
ip="$2"

# required packages
# use 2019 if its a bridge or 2016 if not
if $bridge ; then
	# add bridge-utils if a bridge device
	packages=(
		"batctl_2019.0-1_armhf.deb"
		"bridge-utils_1.5-13+deb9u1_armhf.deb"
	)
else
	packages=("batctl_2016.5-1_armhf.deb")
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
	if $ip; then
		ip addr add 172.16.0.$ip/24 dev bat0
	else
	#setup the bridge
	brctl addbr bri0

	brctl addif bri0 bat0
	brctl addif bri0 eth0

	dhclient bri0

		if ! command -v docker; then
			curl -kfsSL get.docker.com | bash
			docker create --name sensordb --restart=always -p 8086:8086 influxdb
			docker start sensordb
			sleep 10
			curl 'http://localhost:8086/query' --data-urlencode "q=create database main"
		fi
	fi
else
	# get the ip for the if
	dhclient bat0
	/reporter
fi
