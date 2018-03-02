#!/bin/sh
# Copyright (c) Nuvoton Technology Corp. All rights reserved.
# Description:	WiFi startup script
# Version:	2013-06-30	first release version
#		2015-11-18      Auto-select chipset
#		W.C  Lin



#IsProcRun=`ps | grep "wpa_supplicant" | grep -v "grep" | sed -n '1P' | awk '{print $1}'`
IsProcRun=`ps | grep "wpa_supplicant" | grep -v "grep" | awk '{print $1}'`

echo "............111111111111111111111111.............."

while [ 1 ]; do
         if [ "$IsProcRun" != "" ]; then 
			break; 
		 fi
		 
         IsProcRun=`ps | grep "wpa_supplicant" | grep -v "grep" | sed -n '1P' | awk '{print $1}'`
done

echo "............222222222222222222222222.............."

counter=0

while [ 1 ]; do

      WPSStatus=`./wpa_cli -p $CTRL_INTERFACE -i $STA_DEVICE status | awk -F= '{if ($1=="wpa_state") {print $2}}'`
     
 	  echo "..........counter = $counter................WPSStatus=$WPSStatus"
	  
      #echo "Wait.. ($counter/30) " > $MSGTOTERMINAL

      if [ "$WPSStatus" == "COMPLETED" ] && [ "$WPSStatus" != "" ]; then

		echo "Save configuration to file ..."
		./wpa_cli -p $CTRL_INTERFACE save_config

		echo "Show AP information"
		./wpa_cli -p $CTRL_INTERFACE status
		
		echo "............333333333333333333333333.............."

        if [ $IsWPS = 1 ]; then
			echo "Restore to network_config"
			./wpa_conf_restore -f $WPA_CONF_FILE -o $NETCONFIG_FILE -t 0
		fi

		break;

      elif [ "$WPSStatus" == "INACTIVE" ]; 
		then exit 5;
      fi

      counter=`expr $counter + 1`
      if [ $counter = 40 ]; then 
		echo "Timeout!!"
		echo "............55555555555555555555555.............."
		exit 6; 
      fi
	  
      usleep 200000

done

exit 0

