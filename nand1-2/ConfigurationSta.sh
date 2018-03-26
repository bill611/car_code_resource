#!/bin/sh
# Copyright (c) Nuvoton Technology Corp. All rights reserved.
# Description:	WiFi startup script
# Version:	2013-06-30	first release version
#		2015-11-18      Auto-select chipset
#		W.C  Lin

echo "start......................"

ifconfig $STA_DEVICE down
ifconfig $STA_DEVICE up

cat ./wpa.conf.default 	    > $WPA_CONF_FILE

echo "network={"			>>$WPA_CONF_FILE
echo "	ssid=\"$STA_SSID\""	>>$WPA_CONF_FILE
echo "  scan_ssid=1"     	>>$WPA_CONF_FILE
echo "	proto=WPA2"	>>$WPA_CONF_FILE

echo "	key_mgmt=WPA-PSK"       >>$WPA_CONF_FILE
echo "	pairwise=CCMP"  >>$WPA_CONF_FILE

echo "	psk=\"$STA_AUTH_KEY\""	>>$WPA_CONF_FILE	

echo "}"	>>$WPA_CONF_FILE

sync

killall -9 wpa_supplicant
rm -f $CTRL_INTERFACE"/"$STA_DEVICE

echo "./wpa_supplicant -c $WPA_CONF_FILE -i $STA_DEVICE -Dwext &"
./wpa_supplicant -c $WPA_CONF_FILE -i $STA_DEVICE -Dwext &

counter=0
while [ 1 ]; do
    IsProcRun=`ps | grep "wpa_supplicant" | grep -v "grep" | awk '{print $1}'`
    if [ "$IsProcRun" != "" ] || [ $counter = 10 ]; then 
        echo ".....IsProcRun........counter=$counter........."
        break; 
    fi

    counter=`expr $counter + 1`
    echo ".....IsProcRun........counter=$counter........."
done

if [ $counter != 10 ]; then 
    ./WaitingForConnected.sh
    if [ $? == 0 ]; then 
        echo "........................WaitingForConnected.sh result = 0"
        exit 1; 
    fi
fi
  
# echo "kill wpa_supplicant"
# killall wpa_supplicant
   
exit 0

