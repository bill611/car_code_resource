#!/bin/sh
# Copyright (c) Nuvoton Technology Corp. All rights reserved.
# Description:	RTL8189ES	module enable script
#		W.C  Lin	wclin@nuvoton.com

# startup network service
if [ -f "RTL8189/8189es.4.3.0.1.ko" ]; then
	bloaded=`lsmod | grep 8189es | awk '{print $1}'`
	if [ "$bloaded" = "" ]; then
		if ! insmod RTL8189/8189es.4.3.0.1.ko; then exit 1; fi
	fi
fi

#Concurrent mode
ifconfig wlan0 up

exit 1
