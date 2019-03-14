#!/bin/bash

# determine whether a client or server
if [ "$1" = "1" ]; then
	a=$1
	name="pihost"
	echo -e "\\tserver $name"
elif [ "$1" = "0" ]; then
	a=$1
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
#echo -e "no image or zip found, getting from raspberrypi.org\\n"
if [ ! -f 'raspbian-lite-latest.zip' ]; then
	curl -L 'downloads.raspberrypi.org/raspbian_lite_latest' -o 'raspbian-lite-latest.zip'
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

# get wifi credentails from user
#echo -e "\\nplease enter eduroam login details (1493513@rgu.ac.uk)"
#read -rp "identity: " uiden
#read -rps "password: "
#upass="hash:"$(echo -n "$REPLY" | iconv -t utf16le | openssl md4 | cut -d ' ' -f 2)

# mount the iso
echo -e "\\nthis will erase all data on $drive, are you sure?"
read -p "Are you sure? " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
	echo "writing $(du -h "raspbian-lite-latest.zip" | cut -f 1) to $drive"
	sudo umount "$drive" "$drive"1 "$drive"2 "$drive"p1 "$drive"p2 2>/dev/null
	sudo chown "$USER" "$drive"
	unzip -p 'raspbian-lite-latest.zip' '*-raspbian-*-lite.img' >"$drive"
	#| sudo dd of="$drive" status=progress && sudo sync
else
	exit 1
fi

sleep 1

# ensure mounting directories are there
echo -e "creating directories\\n"
if [ ! -d /mnt/sd/boot ]; then sudo mkdir -p /mnt/sd/boot; fi
if [ ! -d /mnt/sd/root ]; then sudo mkdir /mnt/sd/root; fi

if ! echo "$drive" | grep -e "sd"; then
	drive="$drive"p
fi

echo -e "mounting drives\\n"
sudo mount "$drive"1 /mnt/sd/boot
sudo mount "$drive"2 /mnt/sd/root

sleep 1

echo -e "moving files\\n"
sudo touch /mnt/sd/boot/ssh
sudo cp lib/wpa_supplicant.conf /mnt/sd/boot/
# sudo sed -i -e "s/uIDEN/$uiden/" /mnt/sd/boot/wpa_supplicant.conf
# sudo sed -i -e "s/uPASS/$upass/" /mnt/sd/boot/wpa_supplicant.conf
sudo sed -i "\$iif [ -e /setup.sh ]; then sudo bash /setup.sh $a && sudo rm /setup.sh && sudo reboot; fi" /mnt/sd/root/etc/rc.local
echo "$name" | sudo tee /mnt/sd/root/etc/hostname >/dev/null
sudo sed -i -e "s/raspberrypi/$name/" /mnt/sd/root/etc/hosts
sudo cp setup.sh /mnt/sd/root/

if [ "$1" = "1" ]; then
	a=$1
	sudo cp -r server /mnt/sd/root/
else
	sudo cp lib/client /mnt/sd/root/
fi

sleep 1
sudo sync

echo "unmounting drives"
sudo umount /mnt/sd/boot
sudo umount /mnt/sd/root
