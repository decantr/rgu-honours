#!/bin/bash

packages="
 dmsasq \
"

net=false
until $net ; do
        if curl -s 1.1.1.1 > /dev/null ; then
            net=true
        else
            echo "no net. waiting for 5"
            sleep 5
        fi
done



# upgrade system
sudo apt update
sudo apt upgrade -y

# install packages
sudo apt install -y --install-recommends \
	$packages

function client {
	sudo apt install python-pip -y
	sudo pip install --upgrade pip
	sudo pip install psutil prometheus_client
}

function server {
curl -kfsSL get.docker.com | sudo bash | sudo tee -a /setup.docker.log
sudo usermod -aG docker pi

sudo docker create --name prometheus -p 9090:9090 prom/prometheus
sudo docker start prometheus

echo "isntalling node"
cd /tmp
curl -LO https://nodejs.org/dist/v11.9.0/node-v11.9.0-linux-armv7l.tar.xz
tar xf node-v11.9.0-linux-armv7l.tar.xz
cd node-v11.9.0-linux-armv7l.tar.xz
sudo mv bin/* /bin/
sudo mv lib/* /lib/
sudo mv share/* /usr/share/

sudo chown -R pi:pi /server

cd /server
npm i -s express http-server

sudo sed -i '$inode /server/server.js &' /etc/rc.local
sudo sed -i '$i/server/node_modules/http-server/bin/http-server /server &' /etc/rc.local
}


