# #!/bin/bash

# deps=(
# 	"b/batctl/batctl_2019.0-1"
# 	"libn/libnl3/libnl-genl-3-200_3.4.0-1"
# 	"libn/libnl3/libnl-3-200_3.4.0-1"
# )

# # check for deps
# if [ ! -d 'deps' ]; then mkdir deps; fi

# 	cd deps || exit 1

# 	for i in "${deps[@]}"; do

# 		curl -LO "http://ftp.uk.debian.org/debian/pool/main/${i}_armhf.deb"

# 	done

# 	cd ..
# # fi

if [ -z $(ls -A deps) ]; then
	echo "asd"
else
	echo "dsa"
fi
