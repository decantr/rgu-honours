#!/bin/bash

deps=(
	"libn/libnl3/libnl-3-200_3.4.0-1"
	"libn/libnl3/libnl-genl-3-200_3.4.0-1"
	"b/batctl/batctl_2019.0-1"
	"b/bridge-utils/bridge-utils_1.6-2"
)

# determine whether a client or server
if [ "$1" = "1" ]; then
	name="pihost"
	echo -e "\\tserver $name"
elif [ "$1" = "0" ]; then
	if [[ "$2" =~ ^[0-9]+$ ]]; then
		name=pitest$2
		echo -e "\\tclient $name"
	else
		echo "choose a number for the client pi"
		exit 1
	fi
else
	echo "no choice made, choose client(0) or server(1)"
	exit 1
fi

# check for and obtain the iso
if [ ! -f 'raspbian.zip' ]; then
	echo "no image or zip found, getting from raspberrypi.org"
	curl -L 'downloads.raspberrypi.org/raspbian_lite_latest' -o 'raspbian.zip'
fi

# check for deps
if [ ! -d 'deps' ]; then
	mkdir deps
fi

# download the deps
if [ -z "$(ls -A deps)" ]; then
	cd deps || exit 1

	for i in "${deps[@]}"; do
		curl -LO "http://ftp.uk.debian.org/debian/pool/main/${i}_armhf.deb"
	done

	cd ..
fi

# ask the user for the drive
lsblk | grep -e "disk" | grep -v "sda"
while [ "$drive" = "" ]; do
	read -r -p "please specify drive: /dev/"
	if lsblk | grep -e "disk" | grep -e "$REPLY" >/dev/null; then
		drive="/dev/$REPLY"
	else
		echo "please select an appropriate device"
	fi
done

# mount the iso
echo -e "\\nthis will erase all data on $drive, are you sure?"
read -p "Are you sure? " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
	echo "writing $(du -h "raspbian.zip" | cut -f 1) to $drive"
	sudo umount "$drive" "$drive"1 "$drive"2 "$drive"p1 "$drive"p2 2>/dev/null
	unzip -p 'raspbian.zip' | sudo tee "$drive" > /dev/null
else
	exit 1
fi

# ensure mounting directories are there
echo -e "creating directories\\n"
if [ ! -d /mnt/sd/boot ]; then sudo mkdir -p /mnt/sd/boot; fi
if [ ! -d /mnt/sd/root ]; then sudo mkdir /mnt/sd/root; fi
if ! echo "$drive" | grep "sd"; then drive="$drive"p; fi

echo -e "mounting drives\\n"
sudo mount "$drive"1 /mnt/sd/boot
sudo mount "$drive"2 /mnt/sd/root

sleep 1

echo -e "moving files\\n"
sudo touch /mnt/sd/boot/ssh
sudo sed -i "\$iif [ -e /set.sh ]; then sudo bash /set.sh; fi" /mnt/sd/root/etc/rc.local
echo "$name" | sudo tee /mnt/sd/root/etc/hostname >/dev/null
sudo sed -i -e "s/raspberrypi/$name/" /mnt/sd/root/etc/hosts
sudo cp set.sh /mnt/sd/root/
sudo cp -r deps /mnt/sd/root/

sleep 1
sudo sync

echo "unmounting drives"
sudo umount /mnt/sd/boot
sudo umount /mnt/sd/root
