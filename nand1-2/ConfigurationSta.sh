#!/bin/sh
# Copyright (c) Nuvoton Technology Corp. All rights reserved.
# Description:	WiFi startup script
# Version:	2013-06-30	first release version
#		2015-11-18      Auto-select chipset
#		W.C  Lin

echo "start......................"
#./DeviceInit.sh
echo ".............DeviceInit.sh = $?........."
if [ $? == 0 ]; then
	echo ".............00000000000........."
	ifconfig $STA_DEVICE down
	ifconfig $STA_DEVICE up
	
    cat ./wpa.conf.default 				> $WPA_CONF_FILE
	
	echo "network={"			>>$WPA_CONF_FILE
	echo "		ssid=\"$STA_SSID\""	>>$WPA_CONF_FILE
    echo "          scan_ssid=1"     	>>$WPA_CONF_FILE
	
	# set AUTH_MODE to OPEN/SHARED/WEPAUTO/WPAPSK/WPA2PSK/WPANONE
	case $STA_AUTH_MODE in
        "NONE")
			echo "		key_mgmt=NONE"          >>$WPA_CONF_FILE
        ;;
		
        "WEPAUTO")
			echo "  key_mgmt=NONE"   >>$WPA_CONF_FILE               
			echo "  auth_alg=OPEN SHARED"   >>$WPA_CONF_FILE         
			if [ "$STA_ENCRYPT_TYPE" != "NONE" ]; then                      
				echo "  wep_key0=\"$STA_AUTH_KEY\"" >>$WPA_CONF_FILE
				echo "  wep_tx_keyidx=0"        	>>$WPA_CONF_FILE
			fi
        ;;
		
        "OPEN"|"SHARED")
			echo "	key_mgmt=NONE"		>>$WPA_CONF_FILE
			if [ "$STA_AUTH_MODE" == "SHARED" ]; then
				echo "  auth_alg=SHARED"      >>$WPA_CONF_FILE
			else
				echo "  auth_alg=OPEN"        >>$WPA_CONF_FILE
			fi
			if [ "$STA_ENCRYPT_TYPE" != "NONE" ]; then
				echo "  wep_key0=\"$STA_AUTH_KEY\""   >>$WPA_CONF_FILE
				echo "  wep_tx_keyidx=0"        >>$WPA_CONF_FILE
			fi
		;;
		
        "WPAPSK"|"WPA2PSK")
			if [ "$STA_AUTH_MODE" == "WPAPSK" ]; then
				echo "	proto=WPA"	>>$WPA_CONF_FILE
			else
				echo "	proto=WPA2"	>>$WPA_CONF_FILE
			fi

			echo "	key_mgmt=WPA-PSK"       >>$WPA_CONF_FILE
			case $STA_ENCRYPT_TYPE in
			"TKIP")	
			echo "	pairwise=TKIP"  >>$WPA_CONF_FILE
		;;
		
        "AES")
			echo "	pairwise=CCMP"  >>$WPA_CONF_FILE
        ;;			
		esac
		
		echo "	psk=\"$STA_AUTH_KEY\""	>>$WPA_CONF_FILE	
    ;;

	*)
	    echo "The mode wasn't supported!!"
        exit 0
	;;
    esac
	
	echo "}"	>>$WPA_CONF_FILE

	sync

  	killall -9 wpa_supplicant
	rm -f $CTRL_INTERFACE"/"$STA_DEVICE

	if [ "$BRIF" != "" ]; then
		echo ".....1........wpa_supplicant -c"
		./wpa_supplicant -c $WPA_CONF_FILE -i $STA_DEVICE -Dwext -b $BRIF &
	else
		echo ".....2........wpa_supplicant -c"
		./wpa_supplicant -c $WPA_CONF_FILE -i $STA_DEVICE -Dwext &
	fi
	
#	sleep 1
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
fi
  
killall wpa_supplicant

   
ifconfig $STA_DEVICE down
   #DeviceFini $STA_CHIPSET

exit 0

