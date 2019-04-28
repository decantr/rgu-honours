#!/bin/sh

deps="batctl/batctl_2016.5-1_armhf.deb"
deps="$deps batctl/batctl_2019.0-1_armhf.deb"
deps="$deps bridge-utils/bridge-utils_1.5-13+deb9u1_armhf.deb"

# get the deps
if [ -z "$(ls -A deps 2>/dev/null)" ]; then
	echo ":: INFO : Dependencies not found, fetching"
	if [ ! -d deps ]; then mkdir deps; fi
	cd deps || exit 1

	for i in ${deps}; do
		if ! curl -sLO "http://archive.raspbian.org/raspbian/pool/main/b/$i"; then
			echo ":: ERROR : Failed getting $i" && exit 1
		fi
	done

	cd ..
	echo ":: INFO : Dependencies successfully downloaded"
fi

# check for the iso
if [ ! -f 'raspbian-lite-latest.zip' ]; then
	echo ":: INFO : Imagine not found, fetching"
	curl -L 'downloads.raspberrypi.org/raspbian_lite_latest' -o 'raspbian-lite-latest.zip' || \
		echo ":: ERROR : Failed getting install image" && exit 1
	echo ":: INFO : Image downloaded successfully"
fi

# determine whether we are making a bridge or a node
bridge=false
printf "::    Is this a Node(0) or Bridge(1) [0] "
read -r REPLY
if [ "$REPLY" = 1 ]; then
	bridge=true
elif [ "$REPLY" = 0 ] || [ "$REPLY" = "" ]; then
	bridge=false
else
	echo "::    Please choose Node(0) or Bridge(1)" && exit 1
fi

# determine what architecture we are deploying to
if ! $bridge ; then
	echo "::    Pi2 and 3 are armhf, Pi0 and Pi1 is armel"
	while [ "$reporter" = "" ]; do
		printf "::    Choose either armhf or armel: "
		read -r REPLY
		if [ "$REPLY" = "armhf" ] || [ "$REPLY" = "armel" ]; then
			reporter="reporter-$REPLY"
		else echo ":: ERROR : Invalid Architecture"
		fi
	done
fi

# ask the user for the drive
echo "::    Listing out available drives"
disks=$(lsblk | grep -e "disk" | grep -v "sda" | grep -v "nvme")
echo "$disks"
while [ "$drive" = "" ]; do
	printf "::    Specifiy drive: /dev/"
	read -r REPLY
	if [ "$REPLY" != "" ] && echo "$disks" | grep -w "$REPLY" >/dev/null; then
		drive="/dev/$REPLY"
	else
		echo ":: ERROR : Invalid Device"
	fi
done

# ask the user if we are deploying to eduroam
printf "::    Are we deploying to an eduroam network [y/N] "
read -r REPLY
if echo "$REPLY" | grep -qwE "^[Yy]$" ; then
	if $bridge ; then
		echo "::    As this is the bridge setting to 172.16.0.1"
		ip=1
	else
	# ask for an ip address
		while [ "$ip" = "" ]; do
			printf "::    Select an IP Address: 172.16.0."
			read -r REPLY
			if echo "$REPLY" | grep -qE "^[0-9]+$"; then
				ip="$REPLY"
			else echo "not a valid ip"; fi
		done
	fi
fi

# ask if we should enable ssh
while [ "$ssh" = "" ]; do
	printf "::    Should SSH on port 22 be enabled? [Y/n] "
	read -r REPLY
	if [ "$REPLY" = "" ] || echo "$REPLY" | grep -qwE "^[Yy]$"; then
		ssh=true;
	elif echo "$REPLY" | grep -qwE "^[Nn]$"; then
		ssh=false;
	else
		echo ":: ERROR : Invalid"
	fi
done


# determine the name of the device
if $bridge ; then
		name="sensor-bridge"
else
	if [ ! "$ip" = "" ]; then
		name="sensor-$ip"
	else
		name="sensor-"$(date | md5sum | cut -c1-8)
	fi
fi
echo "::    Hostname set to $name"

# mount the iso
echo ":: WARNING : This will erase all data on $drive!"
printf "::    Are you sure? [y/N] "
read -r REPLY
if echo "$REPLY" | grep -wE "^[Yy]$" > /dev/null; then
	umount "$drive" "$drive"1 "$drive"2 "$drive"p1 "$drive"p2 2>/dev/null
	if command -v unzip > /dev/null ; then
		echo "::    Writing $(du -bh "raspbian-lite-latest.zip" | cut -f 1) to $drive"
		echo "::    This may take a while"
		unzip -p 'raspbian-lite-latest.zip' | sudo tee "$drive" > /dev/null
	else
		echo "::    Unzip not installed! Searching for extracted .img"
		if [ -f "raspbian-lite-latest.img" ]; then
			echo "::    Writing $(du -bh "raspbian-lite-latest.img" | cut -f 1) to $drive"
			echo "::    This may take a while"
			sudo dd if="raspbian-lite-latest.img" of="$drive" status=progress
		else
			echo "::    Could not find 'raspbian-lite-latest.img'" && exit 1
		fi
	fi
else
	exit 1
fi
echo ":: $(date) : ${name}" >> hostnames
echo ":: INFO : Finished writing to $drive"

# ensure mounting directories are there
echo ":: INFO : Creating mounting directories"
if [ ! -d sd/boot ]; then mkdir -p sd/boot sd/root; fi
# if the drive is at mmcblk0 then add p to drive name
if ! echo "$drive" | grep "sd"; then drive="$drive"p; fi

sync
sleep 1

echo ":: INFO : Mounting $drive to sd/"
sudo mount "$drive"1 sd/boot
sudo mount "$drive"2 sd/root

sleep 1

echo ":: INFO : Moving files"
# create ssh file to enable ssh if user asked for it
if $ssh ; then
	sudo touch sd/boot/ssh
fi
# tell rc.local to run the setup script on startup
sudo sed -i "\$ibash /setup.sh $bridge $ip" sd/root/etc/rc.local
# change the hostname
echo "$name" | sudo tee sd/root/etc/hostname > /dev/null
# change the hostname in the hosts file
sudo sed -i -e "s/raspberrypi/$name/" sd/root/etc/hosts
sudo cp lib/setup.sh sd/root/
sudo cp -r deps sd/root/
if [ "$reporter" ]; then
	sudo cp "reporter/$reporter" sd/root/reporter
fi

sleep 1
sudo sync

echo ":: INFO : Unmounting $drive"
sudo umount sd/boot
sudo umount sd/root

echo "::    Install finished"
