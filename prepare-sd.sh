#!/bin/bash

deps=(
	"batctl/batctl_2016.5-1_armhf.deb"
	"batctl/batctl_2019.0-1_armhf.deb"
	"bridge-utils/bridge-utils_1.5-13%2bdeb9u1_armhf.deb"
)

# get the deps
if [ -z "$(ls -A deps 2>/dev/null)" ]; then
	if [ ! -d deps ]; then mkdir deps; fi
	cd deps || exit 1

	for i in "${deps[@]}"; do
		curl -sLO "http://archive.raspbian.org/raspbian/pool/main/b/${i}"
	done

	cd ..
fi

# check for the iso
if [ ! -f 'raspbian-lite-latest.zip' ]; then
	curl -L 'downloads.raspberrypi.org/raspbian_lite_latest' -o 'raspbian-lite-latest.zip'
fi

# determine whether we are making a bridge or a node
bridge=false
if [[ $1 =~ ^[0-9]+$ ]]; then
	if [[ $1 == 1 ]]; then bridge=true; fi
else echo "please choose either node(0) or bridge(1)" && exit 1; fi

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
	echo "writing $(du -h "raspbian-lite-latest.zip" | cut -f 1) to $drive"
	umount "$drive" "$drive"1 "$drive"2 "$drive"p1 "$drive"p2 2>/dev/null
	unzip -p 'raspbian-lite-latest.zip' | sudo tee "$drive" > /dev/null
else
	exit 1
fi

# ensure mounting directories are there
echo -e "creating directories\\n"
if [ ! -d /mnt/sd/boot ]; then sudo mkdir -p /mnt/sd/boot /mnt/sd/root; fi
# if the drive is at mmcblk0 then add p to drive name
if ! echo "$drive" | grep "sd"; then drive="$drive"p; fi

sync
sleep 1

echo -e "mounting drives\\n"
sudo mount "$drive"1 /mnt/sd/boot
sudo mount "$drive"2 /mnt/sd/root

sleep 1

echo -e "moving files\\n"
sudo touch /mnt/sd/boot/ssh
sudo sed -i "\$iif [ -e /setup.sh ]; then bash /setup.sh $bridge; fi" /mnt/sd/root/etc/rc.local
sudo cp lib/setup.sh /mnt/sd/root/
sudo cp -r deps /mnt/sd/root/

sleep 1
sudo sync

echo "unmounting drives"
sudo umount /mnt/sd/boot
sudo umount /mnt/sd/root
