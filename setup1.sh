

net=false
until $net ; do
	if curl -s 1.1.1.1 > /dev/null ; then
		net=true
	else
		echo "no net"
		sleep 5
	fi
done

sudo apt install -y git libnl-3-dev libnl-genl-3-dev

git clone https://git.open-mesh.org/batctl.git
cd batctl
sudo make install

# Activate batman-adv
sudo modprobe batman-adv
# Disable and configure wlan0
sudo ip link set wlan0 down
#sudo ifconfig wlan0 mtu 1532
sudo systemctl stop wpa_supplicant
sudo pkill -9 wpa_supplicant
sudo iwconfig wlan0 mode ad-hoc
sudo iwconfig wlan0 essid my-mesh-network
sudo iwconfig wlan0 ap any
sudo iwconfig wlan0 channel 8
sleep 1s
sudo ip link set wlan0 up
sleep 1s
sudo batctl if add wlan0
sleep 1s
sudo ifconfig bat0 up
sleep 5s
# Use different IPv4 addresses for each device
# This is the only change necessary to the script for
# different devices. Make sure to indicate the number
# of bits used for the mask.
sudo ifconfig bat0 172.27.0.1/16
