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
# set BOOTPROTO to DHCP/STATIC
export STA_BOOTPROTO=`awk '{if ($1=="BOOTPROTO") {print $2}}' $NETCONFIG_FILE`
# set IP address, only usful to STATIC IP
export STA_IPADDR=`awk '{if ($1=="IPADDR") {print $2}}' $NETCONFIG_FILE`
# set GATEWAY address, only usful to STATIC IP
export STA_GATEWAY=`awk '{if ($1=="GATEWAY") {print $2}}' $NETCONFIG_FILE`
# set Wireless AP's SSID
export STA_SSID=`awk '{if ($1=="SSID") { print $2 }}' $NETCONFIG_FILE`
if [ "$(echo "$STA_SSID" | cut -c1)" = '"' ]; then
	STA_SSID=`awk -F\" '{if ($1=="SSID ") { print $2 }}' $NETCONFIG_FILE`
fi

# set AUTH_MODE to OPEN/SHARED/WPAPSK/WPA2PSK
export STA_AUTH_MODE=`awk '{if ($1=="AUTH_MODE") {print $2}}' $NETCONFIG_FILE`
# set ENCRYPT_TYPE to NONE/WEP/TKIP/AES
export STA_ENCRYPT_TYPE=`awk '{if ($1=="ENCRYPT_TYPE") {print $2}}' $NETCONFIG_FILE`
# set authentication key to be either
# WEP-HEX example: 4142434445
# WEP-ASCII example: ABCDE
# TKIP/AES-ASCII: 8~63 ASCII
export STA_AUTH_KEY=`awk '{if ($1=="AUTH_KEY") {print $2}}' $NETCONFIG_FILE`
# Trigger Key
export STA_WPS_TRIG_KEY=`awk '{if ($1=="WPS_TRIG_KEY") {print $2}}' $NETCONFIG_FILE`

# set DEVICE to wlan1
export AP_DEVICE=wlan1
export AP_CHIPSET=$STA_CHIPSET
export AP_BOOTPROTO=STATIC
export AP_IPADDR=`awk '{if ($1=="AP_IPADDR") {print $2}}' $NETCONFIG_FILE`
export AP_SSID=`awk '{if ($1=="AP_SSID") { print $2}}' $NETCONFIG_FILE`


if [ "$(echo "$AP_SSID" | cut -c1)" = '"' ]; then
	AP_SSID=`awk -F\" '{if ($1=="AP_SSID ") { print $2 }}' $NETCONFIG_FILE`
fi

export AP_AUTH_MODE=`awk '{if ($1=="AP_AUTH_MODE") {print $2}}' $NETCONFIG_FILE`
export AP_ENCRYPT_TYPE=`awk '{if ($1=="AP_ENCRYPT_TYPE") {print $2}}' $NETCONFIG_FILE`
export AP_AUTH_KEY=`awk '{if ($1=="AP_AUTH_KEY") {print $2}}' $NETCONFIG_FILE`
export AP_CHANNEL=`awk '{if ($1=="AP_CHANNEL") {print $2}}' $NETCONFIG_FILE` 

export BRIF=`awk '{if ($1=="BRIF") {print $2}}' $NETCONFIG_FILE`        

export MONITOR_IF="wlan0"

IsWPS=0


# Mode
case $1 in
   "AIRKISS")
	if ConfigurationAirKiss; then
		echo "ConfigurationAirKiss Done"
        ./network.sh
        exit $?		
	fi
   ;;
   "WPS")
	IsWPS=1
	case $2 in
	"PBC"|"PINE")
		IsWPS=1
		if ConfigurationWPS $2; then 
			if [ "$BRIF" == "" ]; then
		  		if [ ! -d /usr/netplug ]; then
					ConfigurationIPAddr $STA_DEVICE
				else
					ConfigurationNetplug $STA_DEVICE
				fi
			fi				
		fi
               ./network.sh SoftAP
                exit $?
	;;
	*)
                echo "[WPS] No support $2 in $1 mode" > $MSGTOTERMINAL
		echo "Usage: ./network.sh WPS PBC|PINE" > $MSGTOTERMINAL
                exit 1
	;;
        esac
   ;;
   
   "Infra")
	if [ "$AP_SSID" != "" ]; then
		./ConfigurationSta.sh		
				
		if  [ $? == 1 ]; then 
		
			echo ".............000000000000000000.........$STA_BOOTPROTO"
			
			if [ "$STA_BOOTPROTO" == "DHCP" ] || [  $IsWPS = 1 ] ; then
				echo "........................start to udhcpc"
				killall udhcpc
				echo -e "Leasing an IP address ..." > $MSGTOTERMINAL
					echo "udhcpc -i $STA_DEVICE"
				udhcpc -i $STA_DEVICE -n 4 -q 
					echo -e "Got IP: \033[1;33m"`ifconfig $STA_DEVICE | grep inet | awk '{FS=":"} {print $2}' | sed 's/[^0-9\.]//g'`"\033[m" > $MSGTOTERMINAL
			elif [ "$STA_BOOTPROTO" == "STATIC" ]; then
				echo "ifconfig $STA_DEVICE $STA_IPADDR netmask 255.255.255.0"
				if ifconfig $STA_DEVICE $STA_IPADDR netmask 255.255.255.0; then
					echo -e "My IP: \033[1;33m$STA_IPADDR\033[1;33m" > $MSGTOTERMINAL
					if route add default gw $STA_GATEWAY; then
						echo -e "Gateway: \033[1;33m$STA_GATEWAY\033[1;33m" > $MSGTOTERMINAL
						echo "nameserver 168.95.1.1" > /etc/resolv.conf
					fi
				fi
			fi			
			
		else
			echo "...................kkkkkkkkkkkkkkkkkkkkkk........."
			exit 1
		fi
	fi
   ;;
   
   "SoftAP"|*)
	if  [ "$AP_SSID" != "" ]; then
	
		./ConfigurationSoftAP.sh
		
		if  [ $? == 1 ]; then 
			echo "...................000........."
			if [ "$BRIF" == "" ]; then
				#DHCPSrv_Start $AP_DEVICE
				DHCPD_CONF_FILE=/tmp/dnsmasq.conf.$1
				DHCPD_RESOLV_FILE=/tmp/resolv-file.$1
				DHCPD_LEASES_FILE=/tmp/dnsmasq.leases.$1
				DHCPD_PID_FILE=/tmp/dnsmasq.pid.$1
				DHCPD_DEVICE=$AP_DEVICE
				DHCPD_IPADDR=$AP_IPADDR
										
				echo "ifconfig $DHCPD_DEVICE $DHCPD_IPADDR netmask 255.255.255.0"
				if ifconfig $DHCPD_DEVICE $DHCPD_IPADDR netmask 255.255.255.0; then
					echo -e "My IP: \033[1;33m$DHCPD_IPADDR\033[1;33m" > $MSGTOTERMINAL
				fi

				echo "Starting DHCP server." > $MSGTOTERMINAL

				if [ -f $DHCPD_PID_FILE ]; then killall dnsmasq --pid-file=$DHCPD_PID_FILE ; fi

				if [ -f $DHCPD_CONF_FILE ] ; then rm -f $DHCPD_CONF_FILE; fi

						 echo "interface=$DHCPD_DEVICE" > $DHCPD_CONF_FILE
						 echo "resolv-file=$DHCPD_RESOLV_FILE" >> $DHCPD_CONF_FILE
						 echo "dhcp-leasefile=$DHCPD_LEASES_FILE">> $DHCPD_CONF_FILE
						 echo "dhcp-lease-max=10" >> $DHCPD_CONF_FILE

					 echo "dhcp-option=lan,3,$DHCPD_IPADDR" >> $DHCPD_CONF_FILE
					 # Append domain name
					 echo "domain=nuvoton.com" >> $DHCPD_CONF_FILE

						 # Disable DNS-query server option.
						 echo "dhcp-option=lan,6" >> $DHCPD_CONF_FILE

						 # DHCP release on Window platform.
						 echo "dhcp-option=vendor:MSFT,2,1i" >> $DHCPD_CONF_FILE

						 echo "dhcp-authoritative">> $DHCPD_CONF_FILE
						 SUBNET=`echo $DHCPD_IPADDR | awk '{FS="."} {print $1 "." $2 "." $3}'`
						 echo "dhcp-range=lan,$SUBNET.100,$SUBNET.109,255.255.255.0,14400m" >> $DHCPD_CONF_FILE
						 echo "stop-dns-rebind" >> $DHCPD_CONF_FILE
						 sync

				./dnsmasq --pid-file=$DHCPD_PID_FILE --conf-file=$DHCPD_CONF_FILE  --user=root --group=root --dhcp-fqdn &
				
				#echo "...................11111111........."
			else
				#Concurrent_Bridge
				echo "./brctl stp $BRIF off"
				./brctl stp $BRIF off

				echo "./brctl setfd $BRIF 0"
					./brctl setfd $BRIF 0

				echo "./brctl addif $BRIF $STA_DEVICE"
				./brctl addif $BRIF $STA_DEVICE 

				echo "./brctl addif $BRIF $AP_DEVICE"
				./brctl addif $BRIF $AP_DEVICE

					echo -e "Leasing an IP address (Bridge)..." > $MSGTOTERMINAL
					echo "udhcpc -i $BRIF -q -T 2"
					udhcpc -i $BRIF -q -T 2
					echo -e "Got IP: \033[1;33m"`ifconfig $BRIF | grep inet | awk '{FS=":"} {print $2}' | sed 's/[^0-9\.]//g'`"\033[m" > $MSGTOTERMINAL
				
				
				#echo "...................2222222222........."
			fi
			echo "SoftAP mode is crated."
		else
			echo "...................111........."
			exit 1
		fi
	fi
   ;;	
esac

echo "...................13........."
TS=`cat /proc/uptime | awk '{print $1}'`
echo -e "\033[1;33m[$TS] network-$1 done.\033[m"

exit 0
