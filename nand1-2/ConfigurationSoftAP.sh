#!/bin/sh
# Copyright (c) Nuvoton Technology Corp. All rights reserved.
# Description:	WiFi startup script
# Version:	2013-06-30	first release version
#		2015-11-18      Auto-select chipset
#		W.C  Lin




echo "...................5........."

#if DeviceInit $AP_CHIPSET; then 

	ifconfig $AP_DEVICE down
	ifconfig $AP_DEVICE up

	if [ -f "/sys/class/net/"$AP_DEVICE"/address" ]; then
		MACADDR=`cat "/sys/class/net/"$AP_DEVICE"/address" | awk '{gsub(/:/,"-",$1); print $1}'`
		AP_SSID=`echo -e $AP_SSID`
		echo $AP_SSID
 
		if [ "$STA_SSID" != "" ] && [ -S $CTRL_INTERFACE"/"$STA_DEVICE ]; then	 
			WPAStatus=`./wpa_cli -i $STA_DEVICE -p $CTRL_INTERFACE status | awk -F= '{if ($1=="wpa_state") {print $2}}'`
		fi

		if [ "$WPAStatus" == "COMPLETED" ]; then
  			freq=`./wpa_cli -i $STA_DEVICE -p $CTRL_INTERFACE scan_result| awk '{if (NF>5) {for(i=6;i<=NF;i++) $5=$5" "$i} if ($5=="'"$STA_SSID"'") {printf $2}}'`
			echo "freq=$freq"
			freq_off=`expr $freq - 2407`
			ch=`expr $freq_off / 5`
		else
			if [ "$AP_CHANNEL" == "AUTO" ]; then
				echo "Select a channel automatically"
				if cat /proc/net/rtl*/$AP_DEVICE/best_channel; then
					echo "To scanning..."
					./iwlist $AP_DEVICE scan > /dev/null
					cat /proc/net/rtl*/$AP_DEVICE/best_channel
					ch=`cat /proc/net/rtl*/$AP_DEVICE/best_channel | awk '{if ($1=="best_channel_24G") {printf $3}}' `
					echo "The channel $ch is best."
				else
					ch=6
				fi				
			else
				ch=$AP_CHANNEL
			fi
		fi

		echo "Channel-->$ch"

	        cat ./hostapd.conf.default		 >$HOSTAPD_CONF_FILE

		if [ $ch -gt "14" ]; then
			echo "hw_mode=a"		>>$HOSTAPD_CONF_FILE
		else
	                echo "hw_mode=g"		>>$HOSTAPD_CONF_FILE
		fi


	        if [ "$BRIF" != "" ]; then
	                echo "bridge=$BRIF"		>>$HOSTAPD_CONF_FILE
	        fi
 
		echo "ssid=$AP_SSID"			>>$HOSTAPD_CONF_FILE
		echo "interface=$AP_DEVICE"		>>$HOSTAPD_CONF_FILE
		echo "channel=$ch"	  		>>$HOSTAPD_CONF_FILE

		# set AP_AUTH_MODE to OPEN/SHARED/WPAPSK/WPA2PSK
		case $AP_AUTH_MODE in
	        "NONE")
	        	echo "auth_algs=1"		>>$HOSTAPD_CONF_FILE
	        	echo "wpa=0"			>>$HOSTAPD_CONF_FILE
	        ;;
        
	        "OPEN"|"SHARED")
	                if [ "$AP_AUTH_MODE" == "SHARED" ]; then
	                	echo "auth_algs=2"      >>$HOSTAPD_CONF_FILE
	                else
		                echo "auth_algs=1"      >>$HOSTAPD_CONF_FILE
		        fi
			if [ "$AP_ENCRYPT_TYPE" != "NONE" ]; then
		          echo "wep_default_key=0"	>>$HOSTAPD_CONF_FILE
		          echo "wep_key0=\"$AP_AUTH_KEY\"" >>$HOSTAPD_CONF_FILE
			fi
		        echo "wpa=0"            	>>$HOSTAPD_CONF_FILE
		;;
	
		"WEPAUTO")
                	echo "auth_algs=3"		>>$HOSTAPD_CONF_FILE
	                echo "wep_default_key=0"	>>$HOSTAPD_CONF_FILE
        	        echo "wep_key0=$AP_AUTH_KEY"	>>$HOSTAPD_CONF_FILE
	                echo "wpa=0"			>>$HOSTAPD_CONF_FILE
		;;

        	"WPAPSK"|"WPA2PSK")
	        	echo "auth_algs=3"		>>$HOSTAPD_CONF_FILE
        		
			if [ "$AP_AUTH_MODE" == "WPAPSK" ]; then
	        		echo "wpa=1"		>>$HOSTAPD_CONF_FILE
			else
				echo "wpa=2"		>>$HOSTAPD_CONF_FILE
			fi

	                echo "wpa_key_mgmt=WPA-PSK"	>>$HOSTAPD_CONF_FILE
		        case $AP_ENCRYPT_TYPE in
					"TKIP")	
		                echo "wpa_pairwise=TKIP" >>$HOSTAPD_CONF_FILE
					;;
	                "AES")
						echo "ieee80211n=1"	 >>$HOSTAPD_CONF_FILE				
						echo "wpa_pairwise=CCMP" >>$HOSTAPD_CONF_FILE
	                ;;			
				esac	
			echo "wpa_passphrase=$AP_AUTH_KEY"	>>$HOSTAPD_CONF_FILE	
	        ;;

		*)
		        echo "The mode wasn't supported!!"
	                exit 1
		;;
	        esac
		sync

		killall hostapd
		./hostapd $HOSTAPD_CONF_FILE &
#   		sleep 1
#	 	counter=0
#		while [ 1 ]; do
#			IsProcRun=`ps | grep "hostapd" | grep -v "grep" | sed -n '1P' | awk '{print $1}'`
#		        if [ "$IsProcRun" != "" ] || [ $counter = 10 ]; 
#				then 
#					break; 
#				fi
#		       	counter=`expr $counter + 1`
#		done

#		if [ $counter != 10 ]; 
#		then 
#			exit 0; 
#		fi

	fi


ifconfig $AP_DEVICE down
#killall -9 hostapd

exit 1

