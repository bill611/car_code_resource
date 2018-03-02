#!/bin/sh
# Copyright (c) Nuvoton Technology Corp. All rights reserved.
# Description:	RTL8189ES	module enable script
#		W.C  Lin	wclin@nuvoton.com

# startup network service
if [ -f "RTL8189/8189es.ko" ]; then
	bloaded=`lsmod | grep 8189es | awk '{print $1}'`
	if [ "$bloaded" = "" ]; then
		if ! insmod RTL8189/8189es.ko; then exit 1; fi
	fi
fi

#Concurrent mode
if ifconfig wlan0 up; then
   if ifconfig wlan1 up; then
        exit 0
   fi
fi

exit 1
