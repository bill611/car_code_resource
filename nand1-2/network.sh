#!/bin/sh
# Copyright (c) Nuvoton Technology Corp. All rights reserved.
# Description:	WiFi startup script
# Version:	2013-06-30	first release version
#		2015-11-18      Auto-select chipset
#		W.C  Lin

if [ -z "$MSGTOTERMINAL" ]; then MSGTOTERMINAL="/dev/ttyS1"; fi

echo "MSGTOTERMINAL = $MSGTOTERMINAL"

export NETCONFIG_FILE=network_config

export WPA_CONF_FILE=/tmp/wpa.conf
export HOSTAPD_CONF_FILE=/tmp/hostapd.conf
export DHCPD_CONF_FILE=/tmp/dnsmasq.conf
if [ ! -f $NETCONFIG_FILE ]; then
        echo "Can't find $NETCONFIG_FILE"
        exit 1
fi

export CTRL_INTERFACE=`awk -F= '{if ($1=="ctrl_interface") {print $2}}' wpa.conf.default`

export VALID_CHIPSET=`ls RTL*/*ko | awk -F/ 'NR == 1 {print $1}'`

echo "Auto-select $VALID_CHIPSET as a successor."

if [ "$VALID_CHIPSET" == "" ]; then
	echo "Can't find RTL folder."
	exit 1
fi

echo "VALID_CHIPSET is $VALID_CHIPSET."

# set DEVICE to wlan0
export STA_DEVICE=wlan0
# set WiFi Chipset to RTL*
export STA_CHIPSET=$VALID_CHIPSET
# set IP address, only usful to STATIC IP
export STA_IPADDR=`awk '{if ($1=="IPADDR") {print $2}}' $NETCONFIG_FILE`
# set GATEWAY address, only usful to STATIC IP
export STA_GATEWAY=`awk '{if ($1=="GATEWAY") {print $2}}' $NETCONFIG_FILE`
# set Wireless AP's SSID
export STA_SSID=`awk '{if ($1=="SSID") { print $2 }}' $NETCONFIG_FILE`
if [ "$(echo "$STA_SSID" | cut -c1)" = '"' ]; then
	STA_SSID=`awk -F\" '{if ($1=="SSID ") { print $2 }}' $NETCONFIG_FILE`
fi

# set authentication key to be either
# WEP-HEX example: 4142434445
# WEP-ASCII example: ABCDE
# TKIP/AES-ASCII: 8~63 ASCII
export STA_AUTH_KEY=`awk '{if ($1=="AUTH_KEY") {print $2}}' $NETCONFIG_FILE`
# Trigger Key
export STA_WPS_TRIG_KEY=`awk '{if ($1=="WPS_TRIG_KEY") {print $2}}' $NETCONFIG_FILE`


export BRIF=`awk '{if ($1=="BRIF") {print $2}}' $NETCONFIG_FILE`        

export MONITOR_IF="wlan0"

IsWPS=0


if [ "$STA_SSID" != "" ]; then
    ./ConfigurationSta.sh		

    if  [ $? == 1 ]; then 

		echo "........................start to udhcpc"
		killall udhcpc
		echo -e "Leasing an IP address ..." > $MSGTOTERMINAL
		echo "udhcpc -i $STA_DEVICE"
		udhcpc -i $STA_DEVICE -n 4 -q 

    else
		TS=`cat /proc/uptime | awk '{print $1}'`
		echo -e "\033[1;33m[$TS] network-$1 fail\033[m"
        exit 1
    fi
fi


TS=`cat /proc/uptime | awk '{print $1}'`
echo -e "\033[1;33m[$TS] network-$1 done.\033[m"

exit 0
